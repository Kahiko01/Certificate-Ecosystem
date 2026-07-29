"""
Certificate Auto-Generator Service with Role-Based Access Control
"""
from fastapi import FastAPI, HTTPException, Depends, Header
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
import jwt

app = FastAPI(title="Certificate Generator Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "your-super-secret-key-change-in-production"
ALGORITHM = "HS256"

print("Starting Certificate Generator Service with RBAC...", file=sys.stderr, flush=True)

# ===== AUTHENTICATION & AUTHORIZATION =====
def verify_token(token: str) -> dict:
    """Verify JWT token"""
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(authorization: str = Header(...)):
    """Get current user from token"""
    try:
        token = authorization.replace("Bearer ", "")
        payload = verify_token(token)
        return payload
    except:
        raise HTTPException(status_code=401, detail="Invalid authentication")

def is_authorized(user: dict) -> bool:
    """Check if user has permission to generate certificates"""
    # Get user role from payload or user data
    user_role = user.get('role', '')
    print(f"Checking authorization for role: {user_role}", file=sys.stderr, flush=True)
    
    # Allowed roles: SYSTEM_ADMIN and REGISTRAR
    allowed_roles = ['SYSTEM_ADMIN', 'REGISTRAR', 'REGISTRY_HEAD', 'REGISTRY_OFFICER']
    return user_role in allowed_roles

# ===== DATABASE =====
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

# ===== MODELS =====
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

# ===== HELPERS =====
def generate_certificate_number():
    """Generate a unique certificate number"""
    year = datetime.now().year
    num = str(random.randint(1, 999999)).zfill(6)
    return f"CU/{year}/BCom/{num}"

def generate_verification_code():
    """Generate a unique verification code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

# ===== PUBLIC ENDPOINTS =====
@app.get("/")
async def root():
    return {"message": "Certificate Generator Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "certificate-generator", "timestamp": datetime.now().isoformat()}

# ===== PROTECTED ENDPOINTS (Registry & Admin Only) =====
@app.post("/certificates/generate")
async def generate_certificate(
    cert: StudentCertificate,
    current_user: dict = Depends(get_current_user)
):
    """Generate a single certificate for a student - REGISTRY & ADMIN ONLY"""
    # Check authorization
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403, 
            detail="Unauthorized. Only Registry and System Admin can generate certificates."
        )
    
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
            "generated_by": current_user.get('sub', 'system'),
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
        
        print(f"✅ Certificate generated by {current_user.get('sub')}: {cert.student_name}", file=sys.stderr, flush=True)
        
        return {
            "success": True,
            "certificate": certificate_data,
            "message": f"Certificate generated for {cert.student_name}",
            "generated_by": current_user.get('sub')
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error generating certificate: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/bulk-generate")
async def bulk_generate_certificates(
    request: BulkCertificateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Bulk generate certificates - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403, 
            detail="Unauthorized. Only Registry and System Admin can generate certificates."
        )
    
    try:
        results = []
        for student_id in request.student_ids:
            # In production, fetch student details from database
            student_data = {
                "student_id": student_id,
                "student_name": f"Student {student_id[-4:]}",
                "programme": "Bachelor of Science",
                "honours": "Pass",
                "graduation_date": request.graduation_date
            }
            
            # Generate certificate
            cert_number = generate_certificate_number()
            verify_code = generate_verification_code()
            
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
            
            results.append({
                "student_id": student_id,
                "certificate_number": cert_number,
                "verification_code": verify_code,
                "status": "GENERATED"
            })
        
        print(f"✅ Bulk generated {len(results)} certificates by {current_user.get('sub')}", file=sys.stderr, flush=True)
        
        return {
            "success": True,
            "message": f"Generated {len(results)} certificates",
            "certificates": results,
            "generated_by": current_user.get('sub')
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error bulk generating: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates/student/{student_id}")
async def get_student_certificates(
    student_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get all certificates for a student - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403, 
            detail="Unauthorized. Only Registry and System Admin can view certificates."
        )
    
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
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error getting certificates: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/generate-sample")
async def generate_sample_certificates(
    current_user: dict = Depends(get_current_user)
):
    """Generate sample certificates for testing - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403, 
            detail="Unauthorized. Only Registry and System Admin can generate sample certificates."
        )
    
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
        result = await generate_certificate(cert, current_user)
        results.append(result)
    
    return {
        "success": True,
        "message": f"Generated {len(results)} sample certificates",
        "certificates": results,
        "generated_by": current_user.get('sub')
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Certificate Generator with RBAC on port 8005...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8005)
