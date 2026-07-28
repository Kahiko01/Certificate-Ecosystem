from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
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

class LoginRequest(BaseModel):
    username: str
    password: str

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    first_name: str
    last_name: str
    role_name: str
    department_code: Optional[str] = None

@app.get("/")
async def root():
    return {"message": "Authentication Service", "status": "running"}

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

@app.post("/auth/register")
async def register(user: UserCreate):
    """Register a new user with role"""
    conn = get_db()
    if not conn:
        raise HTTPException(status_code=503, detail="Database unavailable")
    
    cur = conn.cursor()
    
    # Check if user exists
    cur.execute("SELECT user_id FROM users WHERE username = %s OR email = %s", (user.username, user.email))
    if cur.fetchone():
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Username or email already exists")
    
    # Check if role exists
    cur.execute("SELECT role_id FROM roles WHERE name = %s", (user.role_name,))
    role_result = cur.fetchone()
    if not role_result:
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail=f"Role '{user.role_name}' not found")
    
    role_id = role_result[0]
    
    # Create user
    user_id = str(uuid.uuid4())
    hashed_password = hash_password(user.password)
    
    cur.execute("""
        INSERT INTO users (user_id, username, email, password_hash, first_name, last_name, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, TRUE)
    """, (user_id, user.username, user.email, hashed_password, user.first_name, user.last_name))
    
    # Assign role
    cur.execute("""
        INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
        VALUES (%s, %s, %s, %s)
    """, (str(uuid.uuid4()), user_id, role_id, user_id))
    
    # If department code provided, add to department
    if user.department_code:
        cur.execute("""
            INSERT INTO department_users (department_user_id, user_id, department_code, is_head)
            VALUES (%s, %s, %s, %s)
        """, (str(uuid.uuid4()), user_id, user.department_code, False))
    
    conn.commit()
    cur.close()
    conn.close()
    
    # Create tokens
    access_token = create_access_token({
        "sub": user.username,
        "user_id": user_id,
        "roles": [user.role_name]
    })
    
    refresh_token = create_refresh_token({
        "sub": user.username,
        "user_id": user_id
    })
    
    return {
        "message": "User registered successfully",
        "user_id": user_id,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@app.get("/auth/me")
async def get_current_user(authorization: str = Header(...)):
    """Get current user information"""
    try:
        token = authorization.replace("Bearer ", "")
        payload = verify_token(token)
        
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT u.user_id, u.username, u.email, u.first_name, u.last_name,
                   array_agg(r.name) as roles,
                   array_agg(r.department_code) as departments
            FROM users u
            LEFT JOIN user_roles ur ON u.user_id = ur.user_id
            LEFT JOIN roles r ON ur.role_id = r.role_id
            WHERE u.user_id = %s AND u.is_active = TRUE
            GROUP BY u.user_id
        """, (payload.get("user_id"),))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_id, username, email, first_name, last_name, roles, departments = result
        
        return {
            "user_id": str(user_id),
            "username": username,
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "roles": roles or [],
            "departments": [d for d in departments if d] or []
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@app.post("/auth/refresh")
async def refresh_token(refresh_token: str):
    """Refresh access token"""
    try:
        payload = verify_token(refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        new_access_token = create_access_token({
            "sub": payload.get("sub"),
            "user_id": payload.get("user_id")
        })
        
        return {"access_token": new_access_token, "token_type": "bearer"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/roles")
async def get_roles():
    """Get all available roles"""
    conn = get_db()
    if not conn:
        raise HTTPException(status_code=503, detail="Database unavailable")
    
    cur = conn.cursor()
    cur.execute("""
        SELECT r.name, r.description, r.department_code,
               array_agg(p.resource || ':' || p.action) as permissions
        FROM roles r
        LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
        LEFT JOIN permissions p ON rp.permission_id = p.permission_id
        GROUP BY r.name, r.description, r.department_code
        ORDER BY r.name
    """)
    
    results = cur.fetchall()
    cur.close()
    conn.close()
    
    roles = []
    for name, description, department, permissions in results:
        roles.append({
            "name": name,
            "description": description,
            "department_code": department,
            "permissions": permissions or []
        })
    
    return {"roles": roles}

if __name__ == "__main__":
    import uvicorn
    print("Starting Authentication Service...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
