from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
from datetime import datetime
import sys

app = FastAPI(title="Email Notification Service")

print("Starting Email Notification Service...", file=sys.stderr, flush=True)

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

class EmailRequest(BaseModel):
    certificate_id: str
    recipient_email: str = ""

@app.get("/")
async def root():
    return {"message": "Email Notification Service", "status": "running"}

@app.get("/health")
async def health():
    db_status = "unhealthy"
    try:
        conn = get_db()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            conn.close()
            db_status = "healthy"
    except Exception as e:
        print(f"Health error: {e}", file=sys.stderr, flush=True)
    
    return {"status": "ok" if db_status == "healthy" else "degraded", "database": db_status}

@app.post("/certificates/email")
async def send_certificate_email(request: EmailRequest):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                c.certificate_number,
                c.verification_code,
                c.issue_date,
                u.first_name,
                u.last_name,
                u.email
            FROM certificates c
            JOIN students s ON c.student_id = s.student_id
            JOIN users u ON s.user_id = u.user_id
            WHERE c.certificate_id = %s
        """, (request.certificate_id,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            raise HTTPException(status_code=404, detail="Certificate not found")
        
        certificate_number, verification_code, issue_date, first_name, last_name, student_email = result
        
        recipient = request.recipient_email or student_email
        
        print(f"📧 Email would be sent to: {recipient}")
        print(f"📧 Certificate: {certificate_number}")
        print(f"📧 Verification Code: {verification_code}")
        
        return {
            "message": "Email sent successfully (simulated)",
            "recipient": recipient,
            "certificate_number": certificate_number,
            "verification_code": verification_code
        }
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
