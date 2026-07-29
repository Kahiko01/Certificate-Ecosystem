"""
Certificate Auto-Generator Service
Automatically generates certificates for graduating students
"""
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import psycopg2
import uuid
import json
from datetime import datetime
import sys
import random
import string
import os

app = FastAPI(title="Certificate Generator Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Certificate Generator Service...", file=sys.stderr, flush=True)

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

class StudentCertificate(BaseModel):
    student_id: str
    student_name: str
    programme: str
    honours: Optional[str] = "Pass"
    graduation_date: str
    registrar_name: Optional[str] = "Dr. Sarah Johnson"
    vice_chancellor_name: Optional[str] = "Prof. Michael Brown"
    dean_name: Optional[str] = "Prof. Alice Smith"

class BulkCertificateRequest(BaseModel):
    student_ids: List[str]
    graduation_date: str

def generate_certificate_number():
    """Generate a unique certificate number"""
    year = datetime.now().year
    num = str(random.randint(1, 999999)).zfill(6)
    return f"CU/{year}/BCom/{num}"

def generate_verification_code():
    """Generate a unique verification code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

@app.get("/")
async def root():
    return {"message": "Certificate Generator Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "certificate-generator", "timestamp": datetime.now().isoformat()}

@app.post("/certificates/generate")
async def generate_certificate(cert: StudentCertificate):
    """Generate a single certificate for a student"""
    try:
        cert_number = generate_certificate_number()
        verify_code = generate_verification_code()
        
        # Generate certificate data
        certificate_data = {
            "certificate_id": str(uuid.uuid4()),
            "certificate_number": cert_number,
            "verification_code": verify_code,
            "student_id": cert.student_id,
            "student_name": cert.student_name,
            "programme": cert.programme,
            "honours": cert.honours,
            "issue_date": cert.graduation_date,
            "registrar": cert.registrar_name,
            "vice_chancellor": cert.vice_chancellor_name,
            "dean": cert.dean_name,
            "status": "GENERATED",
            "created_at": datetime.now().isoformat()
        }
        
        # Store in database
        conn = get_db()
        if conn:
            cur = conn.cursor()
            cur.execute("""
                INSERT INTO certificates (
                    certificate_id, certificate_number, verification_code,
                    student_id, programme, issue_date, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                certificate_data["certificate_id"],
                certificate_data["certificate_number"],
                certificate_data["verification_code"],
                certificate_data["student_id"],
                certificate_data["programme"],
                certificate_data["issue_date"],
                certificate_data["status"]
            ))
            conn.commit()
            cur.close()
            conn.close()
        
        return {
            "success": True,
            "certificate": certificate_data,
            "message": f"Certificate generated for {cert.student_name}"
        }
        
    except Exception as e:
        print(f"Error generating certificate: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/bulk-generate")
async def bulk_generate_certificates(request: BulkCertificateRequest, background_tasks: BackgroundTasks):
    """Bulk generate certificates for multiple students"""
    try:
        results = []
        for student_id in request.student_ids:
            # In production, fetch student details from database
            # For now, use sample data
            student_data = {
                "student_id": student_id,
                "student_name": f"Student {student_id[-4:]}",
                "programme": "Bachelor of Science",
                "honours": "Pass",
                "graduation_date": request.graduation_date
            }
            
            # Generate certificate in background
            background_tasks.add_task(
                generate_single_certificate,
                student_data
            )
            results.append({
                "student_id": student_id,
                "status": "QUEUED"
            })
        
        return {
            "success": True,
            "message": f"Queued {len(request.student_ids)} certificates for generation",
            "queued": results
        }
        
    except Exception as e:
        print(f"Error bulk generating: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

def generate_single_certificate(student_data):
    """Background task to generate a single certificate"""
    try:
        cert_number = generate_certificate_number()
        verify_code = generate_verification_code()
        
        print(f"📜 Generated certificate for {student_data['student_name']}: {cert_number}", file=sys.stderr, flush=True)
        
        # Store in database
        conn = get_db()
        if conn:
            cur = conn.cursor()
            cur.execute("""
                INSERT INTO certificates (
                    certificate_id, certificate_number, verification_code,
                    student_id, issue_date, status
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                str(uuid.uuid4()),
                cert_number,
                verify_code,
                student_data["student_id"],
                student_data["graduation_date"],
                "GENERATED"
            ))
            conn.commit()
            cur.close()
            conn.close()
        
    except Exception as e:
        print(f"Error in background generation: {e}", file=sys.stderr, flush=True)

@app.get("/certificates/student/{student_id}")
async def get_student_certificates(student_id: str):
    """Get all certificates for a student"""
    try:
        conn = get_db()
        if not conn:
            return {"certificates": []}
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_number, verification_code, issue_date, status
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
                "certificate_number": row[0],
                "verification_code": row[1],
                "issue_date": str(row[2]),
                "status": row[3]
            })
        
        return {"student_id": student_id, "certificates": certificates}
        
    except Exception as e:
        print(f"Error getting certificates: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/generate-sample")
async def generate_sample_certificates():
    """Generate sample certificates for testing"""
    sample_students = [
        {"id": "STU001", "name": "John Doe", "programme": "BSc Computer Science", "honours": "First Class"},
        {"id": "STU002", "name": "Jane Smith", "programme": "BSc Business", "honours": "Second Class Upper"},
        {"id": "STU003", "name": "Bob Johnson", "programme": "BSc Engineering", "honours": "Second Class Lower"},
        {"id": "STU004", "name": "Alice Brown", "programme": "BSc Medicine", "honours": "First Class"},
        {"id": "STU005", "name": "Charlie Davis", "programme": "LLB Law", "honours": "Second Class Upper"},
    ]
    
    results = []
    for student in sample_students:
        cert = StudentCertificate(
            student_id=student["id"],
            student_name=student["name"],
            programme=student["programme"],
            honours=student["honours"],
            graduation_date=datetime.now().strftime("%Y-%m-%d")
        )
        result = await generate_certificate(cert)
        results.append(result)
    
    return {
        "success": True,
        "message": f"Generated {len(results)} sample certificates",
        "certificates": results
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Certificate Generator on port 8005...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8005)
