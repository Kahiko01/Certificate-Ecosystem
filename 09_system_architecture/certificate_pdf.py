from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
import os
from datetime import datetime
import sys
import json

app = FastAPI(title="PDF Certificate Service")

print("Starting PDF Certificate Service...", file=sys.stderr, flush=True)

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

class CertificatePDFRequest(BaseModel):
    certificate_id: str

@app.get("/")
async def root():
    return {"message": "PDF Certificate Service", "status": "running"}

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

@app.post("/certificates/pdf")
async def generate_certificate_pdf(request: CertificatePDFRequest):
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
                c.status,
                u.first_name,
                u.last_name
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
        
        certificate_number, verification_code, issue_date, status, first_name, last_name = result
        
        os.makedirs("certificates", exist_ok=True)
        pdf_path = f"certificates/{certificate_number}.txt"
        
        content = f"""
CERTIFICATE OF GRADUATION
=========================

This is to certify that {first_name} {last_name}
has successfully completed the requirements for graduation.

Certificate Number: {certificate_number}
Verification Code: {verification_code}
Issue Date: {issue_date}
Status: {status}

Verify at: http://localhost:8000/verify/{verification_code}
"""
        with open(pdf_path, "w") as f:
            f.write(content)
        
        return {
            "message": "Certificate generated successfully",
            "pdf_path": pdf_path,
            "certificate_number": certificate_number,
            "verification_code": verification_code
        }
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
