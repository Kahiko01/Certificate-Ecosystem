from fastapi import FastAPI
from datetime import datetime
import sys

print("Starting Auth Test Service...", file=sys.stderr)

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Auth Test", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth-test", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    print("Running uvicorn on port 8001...", file=sys.stderr)
    uvicorn.run(app, host="0.0.0.0", port=8001)
