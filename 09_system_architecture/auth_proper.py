from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2
import hashlib
import jwt
from datetime import datetime, timedelta
import sys
import json

app = FastAPI(title="Authentication Service")

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

print("Starting Auth Service...", file=sys.stderr, flush=True)

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

def verify_password(password: str, hashed: str) -> bool:
    try:
        if ':' in hashed:
            salt, hash_value = hashed.split(":")
            return hash_value == hashlib.sha256((salt + password).encode()).hexdigest()
        else:
            return hashlib.sha256(password.encode()).hexdigest() == hashed
    except:
        return False

def create_access_token(data: dict) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    data.update({"exp": expire})
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

class LoginRequest(BaseModel):
    username: str
    password: str

@app.get("/")
async def root():
    return {"message": "Auth Service", "status": "running", "version": "1.0"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"Login attempt: {request.username}", file=sys.stderr, flush=True)
    
    conn = get_db()
    if not conn:
        raise HTTPException(status_code=503, detail="Database unavailable")
    
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT user_id, username, password_hash, first_name, last_name, is_active
            FROM users
            WHERE username = %s
        """, (request.username,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        user_id, username, password_hash, first_name, last_name, is_active = result
        
        if not is_active:
            raise HTTPException(status_code=403, detail="Account deactivated")
        
        if not verify_password(request.password, password_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        access_token = create_access_token({
            "sub": username,
            "user_id": str(user_id),
            "first_name": first_name,
            "last_name": last_name
        })
        
        print(f"Login successful: {username}", file=sys.stderr, flush=True)
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "user_id": str(user_id),
                "username": username,
                "first_name": first_name,
                "last_name": last_name
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Login error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
