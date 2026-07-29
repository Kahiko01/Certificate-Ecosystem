from fastapi import FastAPI
from datetime import datetime

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Auth Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/auth/login")
async def login(username: str, password: str):
    # Simple login for testing
    if username == "system_admin" and password == "admin_hash":
        return {"access_token": "test_token", "token_type": "bearer"}
    return {"error": "Invalid credentials"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
