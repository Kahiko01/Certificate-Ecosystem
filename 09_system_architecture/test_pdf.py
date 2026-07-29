from fastapi import FastAPI
from datetime import datetime
import sys

print("Starting PDF Test Service...", file=sys.stderr)

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "PDF Test", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "pdf-test", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    print("Running uvicorn on port 8003...", file=sys.stderr)
    uvicorn.run(app, host="0.0.0.0", port=8003)
