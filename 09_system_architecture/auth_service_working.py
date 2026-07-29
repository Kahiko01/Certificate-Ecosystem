from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import sys

app = FastAPI(title="Authentication Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Auth Service...", file=sys.stderr, flush=True)

class LoginRequest(BaseModel):
    username: str
    password: str

@app.get("/")
async def root():
    return {"message": "Auth Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(request: LoginRequest):
    print(f"Login attempt: {request.username}", file=sys.stderr, flush=True)
    
    # Hardcoded users for testing
    users = {
        "system_admin": {
            "user_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "admin_hash",
            "first_name": "System",
            "last_name": "Admin",
            "role": "SYSTEM_ADMIN"
        },
        "registrar": {
            "user_id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "default_hash",
            "first_name": "University",
            "last_name": "Registrar",
            "role": "REGISTRAR"
        },
        "finance_head": {
            "user_id": "c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "default_hash",
            "first_name": "Finance",
            "last_name": "Head",
            "role": "FINANCE_HEAD"
        },
        "academic_head": {
            "user_id": "d1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "default_hash",
            "first_name": "Academic",
            "last_name": "Head",
            "role": "ACADEMIC_HEAD"
        },
        "dean": {
            "user_id": "e1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "default_hash",
            "first_name": "Dean",
            "last_name": "of Students",
            "role": "DEAN"
        },
        "student1": {
            "user_id": "f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "password": "default_hash",
            "first_name": "Test",
            "last_name": "Student",
            "role": "STUDENT"
        }
    }
    
    user = users.get(request.username)
    if not user:
        print(f"User not found: {request.username}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if user["password"] != request.password:
        print(f"Invalid password for: {request.username}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    print(f"Login successful: {request.username}", file=sys.stderr, flush=True)
    
    return {
        "access_token": "test_token_" + request.username,
        "token_type": "bearer",
        "user": {
            "user_id": user["user_id"],
            "username": request.username,
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "role": user["role"]
        }
    }

if __name__ == "__main__":
    import uvicorn
    print("Starting Auth Service on port 8001...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8001)
