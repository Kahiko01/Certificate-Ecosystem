from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import sys

app = FastAPI(title="Certificate & Auth Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Service...", file=sys.stderr, flush=True)

class LoginRequest(BaseModel):
    username: str
    password: str

@app.get("/")
async def root():
    return {"message": "Certificate & Auth Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "certificate-auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"Login attempt: {request.username}", file=sys.stderr, flush=True)
    
    users = {
        "system_admin": {"password": "admin_hash", "name": "System Admin", "role": "SYSTEM_ADMIN"},
        "registrar": {"password": "default_hash", "name": "Registrar", "role": "REGISTRAR"},
        "finance_head": {"password": "default_hash", "name": "Finance Head", "role": "FINANCE_HEAD"},
        "academic_head": {"password": "default_hash", "name": "Academic Head", "role": "ACADEMIC_HEAD"},
        "dean": {"password": "default_hash", "name": "Dean", "role": "DEAN"},
        "student1": {"password": "default_hash", "name": "Student", "role": "STUDENT"}
    }
    
    user = users.get(request.username)
    if not user or user["password"] != request.password:
        print(f"Invalid login: {request.username}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    print(f"Login successful: {request.username}", file=sys.stderr, flush=True)
    
    return {
        "access_token": "token_" + request.username,
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
