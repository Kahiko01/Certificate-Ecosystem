from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import sys

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Service...", file=sys.stderr, flush=True)

@app.get("/")
async def root():
    return {"message": "Service Running"}

@app.get("/health")
async def health():
    return {"status": "ok", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(username: str, password: str):
    # Simple login for testing
    if username == "system_admin" and password == "admin_hash":
        return {"access_token": "test_token", "user": {"username": "system_admin", "role": "SYSTEM_ADMIN"}}
    elif username == "registrar" and password == "default_hash":
        return {"access_token": "test_token", "user": {"username": "registrar", "role": "REGISTRAR"}}
    else:
        return {"detail": "Invalid credentials"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
