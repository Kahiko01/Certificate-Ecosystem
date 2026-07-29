from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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

print("Starting Minimal Auth Service...", file=sys.stderr, flush=True)

@app.get("/")
async def root():
    return {"message": "Auth Service", "status": "running", "version": "1.0"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(username: str, password: str):
    # Simple login for testing
    if username == "system_admin" and password == "admin_hash":
        return {
            "access_token": "test_token",
            "token_type": "bearer",
            "user": {
                "user_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
                "username": "system_admin",
                "first_name": "System",
                "last_name": "Admin"
            }
        }
    elif username == "registrar" and password == "default_hash":
        return {
            "access_token": "test_token",
            "token_type": "bearer",
            "user": {
                "user_id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
                "username": "registrar",
                "first_name": "University",
                "last_name": "Registrar"
            }
        }
    elif username == "student1" and password == "default_hash":
        return {
            "access_token": "test_token",
            "token_type": "bearer",
            "user": {
                "user_id": "c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
                "username": "student1",
                "first_name": "Test",
                "last_name": "Student"
            }
        }
    else:
        return {"detail": "Invalid credentials"}, 401

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
