from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uuid
import psycopg2
from datetime import datetime
import sys
import time

app = FastAPI(title="Certificate Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Certificate Service...", file=sys.stderr, flush=True)

def get_db():
    try:
        print("Connecting to PostgreSQL...", file=sys.stderr, flush=True)
        conn = psycopg2.connect(
            host="certificate-postgres",
            database="certificate_ecosystem",
            user="cert_admin",
            password="secure_password_123",
            connect_timeout=5
        )
        print("PostgreSQL connected!", file=sys.stderr, flush=True)
        return conn
    except Exception as e:
        print(f"DB Error: {e}", file=sys.stderr, flush=True)
        return None

@app.get("/")
async def root():
    return {
        "message": "Certificate Service",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    }

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
    
    return {
        "status": "ok" if db_status == "healthy" else "degraded",
        "database": db_status,
        "timestamp": datetime.now().isoformat()
    }

class CertCreate(BaseModel):
    student_id: str
    programme_id: str
    issue_date: str

@app.post("/certificates")
async def create_cert(cert: CertCreate):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cert_id = str(uuid.uuid4())
        cert_num = f"CERT-{datetime.now().year}-{str(uuid.uuid4())[:8].upper()}"
        verify_code = str(uuid.uuid4())[:8].upper()
        
        cur.execute("""
            INSERT INTO certificates (
                certificate_id, certificate_number, verification_code,
                student_id, programme_id, issue_date, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (cert_id, cert_num, verify_code, cert.student_id, cert.programme_id, cert.issue_date, 'ISSUED'))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {
            "certificate_id": cert_id,
            "certificate_number": cert_num,
            "verification_code": verify_code,
            "status": "ISSUED",
            "issue_date": cert.issue_date
        }
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates")
async def list_certificates(limit: int = 15):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_id, certificate_number, verification_code, status, issue_date
            FROM certificates
            ORDER BY created_at DESC
            LIMIT %s
        """, (limit,))
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        certificates = []
        for row in results:
            certificates.append({
                "certificate_id": row[0],
                "certificate_number": row[1],
                "verification_code": row[2],
                "status": row[3],
                "issue_date": str(row[4])
            })
        
        return {"certificates": certificates, "count": len(certificates)}
    except Exception as e:
        print(f"Error listing: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates/{certificate_id}")
async def get_certificate(certificate_id: str):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_id, certificate_number, verification_code, status, issue_date
            FROM certificates
            WHERE certificate_id = %s
        """, (certificate_id,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            raise HTTPException(status_code=404, detail="Certificate not found")
        
        return {
            "certificate_id": result[0],
            "certificate_number": result[1],
            "verification_code": result[2],
            "status": result[3],
            "issue_date": str(result[4])
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/verify/{verification_code}")
async def verify_cert(verification_code: str):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_id, certificate_number, status, issue_date
            FROM certificates
            WHERE verification_code = %s
        """, (verification_code,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            return {"valid": False, "message": "Certificate not found"}
        
        return {
            "valid": True,
            "certificate_id": result[0],
            "certificate_number": result[1],
            "status": result[2],
            "issue_date": str(result[3])
        }
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/students/{student_id}/certificates")
async def get_student_certificates(student_id: str):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_id, certificate_number, verification_code, status, issue_date
            FROM certificates
            WHERE student_id = %s
            ORDER BY created_at DESC
        """, (student_id,))
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        certificates = []
        for row in results:
            certificates.append({
                "certificate_id": row[0],
                "certificate_number": row[1],
                "verification_code": row[2],
                "status": row[3],
                "issue_date": str(row[4])
            })
        
        return {"student_id": student_id, "certificates": certificates, "count": len(certificates)}
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
async def get_stats():
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        cur.execute("SELECT COUNT(*) FROM certificates")
        total_certificates = cur.fetchone()[0]
        
        cur.execute("SELECT status, COUNT(*) FROM certificates GROUP BY status")
        status_counts = cur.fetchall()
        
        cur.execute("SELECT COUNT(*) FROM students")
        total_students = cur.fetchone()[0]
        
        cur.close()
        conn.close()
        
        status_breakdown = {}
        for status, count in status_counts:
            status_breakdown[status] = count
        
        return {
            "total_certificates": total_certificates,
            "total_students": total_students,
            "certificates_by_status": status_breakdown,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    print("Starting uvicorn server...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8000)
