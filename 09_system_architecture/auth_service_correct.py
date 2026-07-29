from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
import sys
import jwt
import uuid

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

print("🚀 Starting Authentication Service...", file=sys.stderr, flush=True)

# Hardcoded users
USERS = {
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
    "academic_head": {
        "password": "default_hash",
        "name": "Academic Head",
        "role": "ACADEMIC_HEAD",
        "user_id": "d1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
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
    return {"message": "Authentication Service", "status": "running", "version": "1.0"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"📝 Login attempt: {request.username}", file=sys.stderr, flush=True)
    
    user = USERS.get(request.username)
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
    print("🔥 Auth Service running on port 8001", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
