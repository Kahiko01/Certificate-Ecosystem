from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import uuid
import psycopg2
import hashlib
import secrets
import jwt
from datetime import datetime, timedelta
import sys
import json
import requests

app = FastAPI(title="Authentication Service with Tracking")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "your-super-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

print("Starting Authentication Service with Tracking...", file=sys.stderr, flush=True)

def get_db():
    try:
        conn = psycopg2.connect(
            host="certificate-postgres",
            database="certificate_ecosystem",
            user="cert_admin",
            password="secure_password_123",
            connect_timeout=5
        )
        return conn
    except Exception as e:
        print(f"DB Error: {e}", file=sys.stderr, flush=True)
        return None

def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    return salt + ":" + hashlib.sha256((salt + password).encode()).hexdigest()

def verify_password(password: str, hashed: str) -> bool:
    try:
        salt, hash_value = hashed.split(":")
        return hash_value == hashlib.sha256((salt + password).encode()).hexdigest()
    except:
        return False

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_device_info(user_agent: str) -> dict:
    """Parse user agent to get device info"""
    device_info = {
        "device_type": "Unknown",
        "browser": "Unknown",
        "os": "Unknown"
    }
    
    if not user_agent:
        return device_info
    
    ua = user_agent.lower()
    
    # Device type
    if "mobile" in ua or "android" in ua or "iphone" in ua:
        device_info["device_type"] = "Mobile"
    elif "tablet" in ua or "ipad" in ua:
        device_info["device_type"] = "Tablet"
    else:
        device_info["device_type"] = "Desktop"
    
    # Browser
    if "chrome" in ua and "edge" not in ua:
        device_info["browser"] = "Chrome"
    elif "firefox" in ua:
        device_info["browser"] = "Firefox"
    elif "safari" in ua and "chrome" not in ua:
        device_info["browser"] = "Safari"
    elif "edge" in ua:
        device_info["browser"] = "Edge"
    elif "opera" in ua:
        device_info["browser"] = "Opera"
    
    # OS
    if "windows" in ua:
        device_info["os"] = "Windows"
    elif "mac" in ua:
        device_info["os"] = "macOS"
    elif "linux" in ua:
        device_info["os"] = "Linux"
    elif "android" in ua:
        device_info["os"] = "Android"
    elif "iphone" in ua or "ipad" in ua:
        device_info["os"] = "iOS"
    
    return device_info

def log_login_attempt(user_id: str, username: str, status: str, request: Request, 
                      session_id: str = None, failure_reason: str = None):
    """Log login attempt"""
    try:
        conn = get_db()
        if not conn:
            return
        
        ip = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent", "")
        device_info = get_device_info(user_agent)
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO login_history (
                login_id, user_id, username, login_time, ip_address, user_agent,
                login_status, failure_reason, session_id, device_type, browser, os
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            str(uuid.uuid4()),
            user_id,
            username,
            datetime.now(),
            ip,
            user_agent,
            status,
            failure_reason,
            session_id,
            device_info["device_type"],
            device_info["browser"],
            device_info["os"]
        ))
        
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error logging login attempt: {e}", file=sys.stderr, flush=True)

def create_active_session(user_id: str, username: str, request: Request, session_id: str):
    """Create active session entry"""
    try:
        conn = get_db()
        if not conn:
            return
        
        ip = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent", "")
        device_info = get_device_info(user_agent)
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO active_sessions (
                session_id, user_id, username, login_time, last_activity,
                ip_address, user_agent, device_type, browser, os, is_active
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
        """, (
            session_id,
            user_id,
            username,
            datetime.now(),
            datetime.now(),
            ip,
            user_agent,
            device_info["device_type"],
            device_info["browser"],
            device_info["os"]
        ))
        
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error creating active session: {e}", file=sys.stderr, flush=True)

def update_session_activity(session_id: str):
    """Update session last activity"""
    try:
        conn = get_db()
        if not conn:
            return
        
        cur = conn.cursor()
        cur.execute("""
            UPDATE active_sessions 
            SET last_activity = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
            WHERE session_id = %s AND is_active = TRUE
        """, (session_id,))
        
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error updating session activity: {e}", file=sys.stderr, flush=True)

def logout_session(session_id: str, user_id: str, username: str):
    """Logout user and update session"""
    try:
        conn = get_db()
        if not conn:
            return
        
        cur = conn.cursor()
        
        # Update active session
        cur.execute("""
            UPDATE active_sessions 
            SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
            WHERE session_id = %s AND user_id = %s
        """, (session_id, user_id))
        
        # Update login history with logout time
        cur.execute("""
            UPDATE login_history 
            SET logout_time = CURRENT_TIMESTAMP,
                session_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - login_time))::INTEGER,
                login_status = 'LOGGED_OUT'
            WHERE session_id = %s AND user_id = %s AND login_status = 'SUCCESS'
        """, (session_id, user_id))
        
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error logging out: {e}", file=sys.stderr, flush=True)

class LoginRequest(BaseModel):
    username: str
    password: str

class LogoutRequest(BaseModel):
    session_id: str

@app.post("/auth/login")
async def login(request: LoginRequest, req: Request):
    """Login and get access token with tracking"""
    conn = get_db()
    if not conn:
        raise HTTPException(status_code=503, detail="Database unavailable")
    
    cur = conn.cursor()
    
    # Get user with roles
    cur.execute("""
        SELECT u.user_id, u.username, u.email, u.password_hash, u.first_name, u.last_name,
               array_agg(r.name) as roles,
               array_agg(r.department_code) as departments
        FROM users u
        LEFT JOIN user_roles ur ON u.user_id = ur.user_id
        LEFT JOIN roles r ON ur.role_id = r.role_id
        WHERE u.username = %s AND u.is_active = TRUE
        GROUP BY u.user_id
    """, (request.username,))
    
    result = cur.fetchone()
    
    if not result:
        # Log failed login attempt
        log_login_attempt(None, request.username, "FAILED", req, failure_reason="User not found")
        cur.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user_id, username, email, password_hash, first_name, last_name, roles, departments = result
    
    if not verify_password(request.password, password_hash):
        # Log failed login attempt
        log_login_attempt(str(user_id), username, "FAILED", req, failure_reason="Invalid password")
        cur.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    cur.close()
    conn.close()
    
    # Generate session ID
    session_id = str(uuid.uuid4())
    
    # Log successful login
    log_login_attempt(str(user_id), username, "SUCCESS", req, session_id)
    
    # Create active session
    create_active_session(str(user_id), username, req, session_id)
    
    # Create tokens
    access_token = create_access_token({
        "sub": username,
        "user_id": str(user_id),
        "session_id": session_id,
        "roles": roles or []
    })
    
    refresh_token = create_refresh_token({
        "sub": username,
        "user_id": str(user_id),
        "session_id": session_id
    })
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "session_id": session_id,
        "user": {
            "user_id": str(user_id),
            "username": username,
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "roles": roles or [],
            "departments": [d for d in departments if d] or []
        },
        "login_time": datetime.now().isoformat()
    }

@app.post("/auth/logout")
async def logout(request: LogoutRequest, req: Request):
    """Logout user"""
    try:
        # Get user from session
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT user_id, username FROM active_sessions 
            WHERE session_id = %s AND is_active = TRUE
        """, (request.session_id,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if result:
            user_id, username = result
            logout_session(request.session_id, str(user_id), username)
            return {"message": "Logged out successfully", "session_id": request.session_id}
        else:
            return {"message": "Session already inactive or not found"}
            
    except Exception as e:
        print(f"Logout error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/online-users")
async def get_online_users():
    """Get currently online users"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT * FROM vw_online_users
            ORDER BY last_activity DESC
        """)
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        users = []
        for row in results:
            users.append({
                "user_id": str(row[0]),
                "username": row[1],
                "first_name": row[2],
                "last_name": row[3],
                "login_time": row[4].isoformat() if row[4] else None,
                "last_activity": row[5].isoformat() if row[5] else None,
                "session_duration": row[6],
                "ip_address": str(row[7]) if row[7] else None,
                "device_type": row[8],
                "browser": row[9],
                "os": row[10],
                "roles": row[11] if row[11] else []
            })
        
        return {"online_users": users, "count": len(users)}
        
    except Exception as e:
        print(f"Error getting online users: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/login-history/{user_id}")
async def get_user_login_history(user_id: str, limit: int = 50):
    """Get login history for a specific user"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT * FROM vw_user_login_history
            WHERE user_id = %s
            LIMIT %s
        """, (user_id, limit))
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        history = []
        for row in results:
            history.append({
                "login_id": str(row[0]),
                "username": row[1],
                "first_name": row[2],
                "last_name": row[3],
                "login_time": row[4].isoformat() if row[4] else None,
                "logout_time": row[5].isoformat() if row[5] else None,
                "session_duration": row[6],
                "ip_address": str(row[7]) if row[7] else None,
                "device_type": row[8],
                "browser": row[9],
                "os": row[10],
                "status": row[11],
                "session_status": row[12]
            })
        
        return {"user_id": user_id, "history": history, "count": len(history)}
        
    except Exception as e:
        print(f"Error getting login history: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/session-stats")
async def get_session_stats():
    """Get session statistics"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Get online users count
        cur.execute("SELECT COUNT(*) FROM active_sessions WHERE is_active = TRUE AND last_activity > NOW() - INTERVAL '15 minutes'")
        online_count = cur.fetchone()[0]
        
        # Get today's login stats
        cur.execute("""
            SELECT 
                COUNT(*) as total_logins,
                COUNT(DISTINCT user_id) as unique_users,
                COUNT(CASE WHEN login_status = 'SUCCESS' THEN 1 END) as successful,
                COUNT(CASE WHEN login_status = 'FAILED' THEN 1 END) as failed
            FROM login_history
            WHERE DATE(login_time) = CURRENT_DATE
        """)
        today_stats = cur.fetchone()
        
        # Get weekly trend
        cur.execute("""
            SELECT 
                DATE(login_time) as date,
                COUNT(*) as logins
            FROM login_history
            WHERE login_time > NOW() - INTERVAL '7 days'
            GROUP BY DATE(login_time)
            ORDER BY date
        """)
        weekly_data = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return {
            "online_users": online_count,
            "today": {
                "total_logins": today_stats[0] or 0,
                "unique_users": today_stats[1] or 0,
                "successful": today_stats[2] or 0,
                "failed": today_stats[3] or 0
            },
            "weekly_trend": [{"date": w[0].isoformat(), "logins": w[1]} for w in weekly_data],
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Error getting session stats: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

# Keep the existing endpoints from the original auth service
# ... (register, me, refresh, roles endpoints remain the same)

if __name__ == "__main__":
    import uvicorn
    print("Starting Authentication Service with Tracking...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
