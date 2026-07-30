from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
import sys
import uuid
import jwt
import hashlib
import secrets
import psycopg2
import os

app = FastAPI(title="Authentication Service with Database")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "your-super-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

print("🚀 Starting Auth Service with Database...", file=sys.stderr, flush=True)

def get_db():
    try:
        # Try to connect to PostgreSQL
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

# Hardcoded users for fallback if DB is not available
FALLBACK_USERS = {
    "system_admin": {
        "password": "admin_hash",
        "name": "System Admin",
        "role": "SYSTEM_ADMIN",
        "user_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    },
    "registrar": {
        "password": "default_hash",
        "name": "Registrar",
        "role": "REGISTRAR",
        "user_id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    },
    "finance_head": {
        "password": "default_hash",
        "name": "Finance Head",
        "role": "FINANCE_HEAD",
        "user_id": "c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    },
    "dean": {
        "password": "default_hash",
        "name": "Dean",
        "role": "DEAN",
        "user_id": "e1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    },
    "student1": {
        "password": "default_hash",
        "name": "Student",
        "role": "STUDENT",
        "user_id": "f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    }
}

class LoginRequest(BaseModel):
    username: str
    password: str

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@app.get("/")
async def root():
    return {"message": "Authentication Service", "status": "running"}

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
        print(f"Health DB check: {e}", file=sys.stderr, flush=True)
    
    return {
        "status": "ok" if db_status == "healthy" else "degraded",
        "database": db_status,
        "service": "auth",
        "timestamp": datetime.now().isoformat()
    }

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"📝 Login attempt: {request.username}", file=sys.stderr, flush=True)
    
    # Try database first
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("""
                SELECT user_id, username, password_hash, first_name, last_name
                FROM users
                WHERE username = %s AND is_active = TRUE
            """, (request.username,))
            result = cur.fetchone()
            cur.close()
            conn.close()
            
            if result:
                # User found in database - verify password
                # For demo, use simple check
                if request.password == "admin_hash" or request.password == "default_hash":
                    user_id, username, password_hash, first_name, last_name = result
                    access_token = create_access_token({
                        "sub": username,
                        "user_id": str(user_id),
                        "role": "USER"
                    })
                    return {
                        "access_token": access_token,
                        "token_type": "bearer",
                        "user": {
                            "user_id": str(user_id),
                            "username": username,
                            "name": f"{first_name} {last_name}",
                            "role": "USER"
                        }
                    }
        except Exception as e:
            print(f"DB Query error: {e}", file=sys.stderr, flush=True)
    
    # Fallback to hardcoded users
    user = FALLBACK_USERS.get(request.username)
    if not user:
        print(f"❌ User not found: {request.username}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if user["password"] != request.password:
        print(f"❌ Invalid password for: {request.username}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    print(f"✅ Login successful: {request.username}", file=sys.stderr, flush=True)
    
    access_token = create_access_token({
        "sub": request.username,
        "user_id": user["user_id"],
        "role": user["role"]
    })
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "user_id": user["user_id"],
            "username": request.username,
            "name": user["name"],
            "role": user["role"]
        }
    }

if __name__ == "__main__":
    import uvicorn
    print("🔥 Auth Service running on http://0.0.0.0:8001", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
