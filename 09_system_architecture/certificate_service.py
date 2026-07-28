from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import uuid
import psycopg2
import redis
import json
from datetime import datetime
import time

app = FastAPI(title="Certificate Service", version="1.0.0")

# Database connection with retry
def get_db():
    max_retries = 5
    retry_delay = 3
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                host="certificate-postgres",
                database="certificate_ecosystem",
                user="cert_admin",
                password="secure_password_123",
                connect_timeout=10
            )
            return conn
        except Exception as e:
            print(f"Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
            else:
                raise
    return None

# Redis connection
def get_redis():
    try:
        return redis.Redis(host='certificate-redis', port=6379, decode_responses=True)
    except Exception as e:
        print(f"Redis connection error: {e}")
        return None

# Models
class CertificateCreate(BaseModel):
    student_id: str
    programme_id: str
    issue_date: str

@app.get("/")
async def root():
    return {
        "message": "Certificate Service is running",
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health")
async def health():
    # Check database
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
        print(f"Health check DB error: {e}")
    
    # Check redis
    redis_status = "unhealthy"
    try:
        r = get_redis()
        if r:
            r.ping()
            redis_status = "healthy"
    except:
        pass
    
    return {
        "status": "ok" if db_status == "healthy" and redis_status == "healthy" else "degraded",
        "database": db_status,
        "redis": redis_status,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/certificates")
async def create_certificate(cert: CertificateCreate):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Generate certificate
        certificate_id = str(uuid.uuid4())
        certificate_number = f"CERT-{datetime.now().year}-{str(uuid.uuid4())[:8].upper()}"
        verification_code = str(uuid.uuid4())[:8].upper()
        
        # Insert into database
        cur.execute("""
            INSERT INTO certificates (
                certificate_id, certificate_number, verification_code,
                student_id, programme_id, issue_date, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING certificate_id
        """, (
            certificate_id, certificate_number, verification_code,
            cert.student_id, cert.programme_id, cert.issue_date, 'ISSUED'
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        
        # Cache in Redis
        r = get_redis()
        if r:
            try:
                r.setex(
                    f"cert:{certificate_id}",
                    3600,
                    json.dumps({
                        "certificate_id": certificate_id,
                        "certificate_number": certificate_number,
                        "verification_code": verification_code,
                        "status": "ISSUED",
                        "issue_date": cert.issue_date
                    })
                )
            except:
                pass
        
        return {
            "certificate_id": certificate_id,
            "certificate_number": certificate_number,
            "verification_code": verification_code,
            "status": "ISSUED",
            "issue_date": cert.issue_date
        }
        
    except Exception as e:
        print(f"Error creating certificate: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates/{certificate_id}")
async def get_certificate(certificate_id: str):
    # Check cache first
    r = get_redis()
    if r:
        try:
            cached = r.get(f"cert:{certificate_id}")
            if cached:
                return json.loads(cached)
        except:
            pass
    
    # Query database
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        cur.execute("""
            SELECT certificate_number, verification_code, status, issue_date
            FROM certificates
            WHERE certificate_id = %s
        """, (certificate_id,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            raise HTTPException(status_code=404, detail="Certificate not found")
        
        certificate_data = {
            "certificate_id": certificate_id,
            "certificate_number": result[0],
            "verification_code": result[1],
            "status": result[2],
            "issue_date": str(result[3])
        }
        
        if r:
            try:
                r.setex(f"cert:{certificate_id}", 3600, json.dumps(certificate_data))
            except:
                pass
        
        return certificate_data
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error getting certificate: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/verify/{verification_code}")
async def verify_certificate(verification_code: str):
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        cur.execute("""
            SELECT certificate_id, certificate_number, status, issue_date, student_id
            FROM certificates
            WHERE verification_code = %s
        """, (verification_code,))
        
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if not result:
            return {
                "valid": False, 
                "message": "Certificate not found",
                "timestamp": datetime.now().isoformat()
            }
        
        return {
            "valid": True,
            "certificate_id": result[0],
            "certificate_number": result[1],
            "status": result[2],
            "issue_date": str(result[3]),
            "verification_timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Error verifying certificate: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates")
async def list_certificates(limit: int = 10, offset: int = 0):
    """List all certificates with pagination"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                c.certificate_id,
                c.certificate_number,
                c.verification_code,
                c.status,
                c.issue_date,
                s.student_number,
                u.first_name,
                u.last_name
            FROM certificates c
            JOIN students s ON c.student_id = s.student_id
            JOIN users u ON s.user_id = u.user_id
            ORDER BY c.created_at DESC
            LIMIT %s OFFSET %s
        """, (limit, offset))
        
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
                "issue_date": str(row[4]),
                "student_number": row[5],
                "student_name": f"{row[6]} {row[7]}"
            })
        
        return {"certificates": certificates, "count": len(certificates)}
        
    except Exception as e:
        print(f"Error listing certificates: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/students/{student_id}/certificates")
async def get_student_certificates(student_id: str):
    """Get all certificates for a student"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                certificate_id,
                certificate_number,
                verification_code,
                status,
                issue_date
            FROM certificates
            WHERE student_id = %s
            ORDER BY issue_date DESC
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
        print(f"Error getting student certificates: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
async def get_stats():
    """Get system statistics"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Total certificates
        cur.execute("SELECT COUNT(*) FROM certificates")
        total_certificates = cur.fetchone()[0]
        
        # Certificates by status
        cur.execute("SELECT status, COUNT(*) FROM certificates GROUP BY status")
        status_counts = cur.fetchall()
        
        # Total students
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
        print(f"Error getting stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
