from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
import sys
import jwt

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

print("🚀 Starting Auth Service...", file=sys.stderr, flush=True)

USERS = {
    "system_admin": {"password": "admin_hash", "name": "System Admin", "role": "SYSTEM_ADMIN"},
    "registrar": {"password": "default_hash", "name": "Registrar", "role": "REGISTRAR"},
    "finance_head": {"password": "default_hash", "name": "Finance Head", "role": "FINANCE_HEAD"},
    "dean": {"password": "default_hash", "name": "Dean", "role": "DEAN"},
    "student1": {"password": "default_hash", "name": "Student", "role": "STUDENT"}
}

class LoginRequest(BaseModel):
    username: str
    password: str

def create_access_token(data: dict) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    data.update({"exp": expire})
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

@app.get("/")
async def root():
    return {"message": "Auth Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"📝 Login: {request.username}", file=sys.stderr, flush=True)
    
    user = USERS.get(request.username)
    if not user or user["password"] != request.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token({
        "sub": request.username,
        "role": user["role"]
    })
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "username": request.username,
            "name": user["name"],
            "role": user["role"]
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
