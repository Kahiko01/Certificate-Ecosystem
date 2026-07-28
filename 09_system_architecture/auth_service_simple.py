from fastapi import FastAPI, HTTPException, Request
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

app = FastAPI(title="Authentication Service")

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

print("Starting Authentication Service...", file=sys.stderr, flush=True)

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

@app.get("/")
async def root():
    return {"message": "Authentication Service", "status": "running", "version": "1.0"}

@app.get("/health")
async def health():
    db_status = "unhealthy"
    try:
        conn = get_db()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            conn.close()
            db_status = "healthy"
    except Exception as e:
        print(f"Health error: {e}", file=sys.stderr, flush=True)
    
    return {"status": "ok" if db_status == "healthy" else "degraded", "database": db_status}

class LoginRequest(BaseModel):
    username: str
    password: str

@app.post("/auth/login")
async def login(request: LoginRequest):
    """Login and get access token"""
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
    cur.close()
    conn.close()
    
    if not result:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user_id, username, email, password_hash, first_name, last_name, roles, departments = result
    
    if not verify_password(request.password, password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create tokens
    access_token = create_access_token({
        "sub": username,
        "user_id": str(user_id),
        "roles": roles or []
    })
    
    refresh_token = create_refresh_token({
        "sub": username,
        "user_id": str(user_id)
    })
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "user_id": str(user_id),
            "username": username,
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "roles": roles or [],
            "departments": [d for d in departments if d] or []
        }
    }

@app.get("/auth/online-users")
async def get_online_users():
    """Get online users (simplified for now)"""
    return {
        "online_users": [
            {
                "user_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
                "username": "system_admin",
                "first_name": "System",
                "last_name": "Admin",
                "login_time": datetime.now().isoformat(),
                "last_activity": datetime.now().isoformat(),
                "session_duration": 3600,
                "ip_address": "127.0.0.1",
                "device_type": "Desktop",
                "browser": "Chrome",
                "os": "Linux",
                "roles": ["SYSTEM_ADMIN"]
            }
        ],
        "count": 1
    }

@app.get("/auth/session-stats")
async def get_session_stats():
    """Get session statistics"""
    return {
        "online_users": 1,
        "today": {
            "total_logins": 5,
            "unique_users": 3,
            "successful": 4,
            "failed": 1
        },
        "weekly_trend": [],
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    print("Starting Authentication Service...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
