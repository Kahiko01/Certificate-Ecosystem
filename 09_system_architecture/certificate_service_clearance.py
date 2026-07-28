from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import uuid
import psycopg2
from datetime import datetime
import sys
import hashlib
import secrets

app = FastAPI(title="Certificate Service with Clearance")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Certificate Service with Clearance...", file=sys.stderr, flush=True)

# Database connection
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

# Models
class StudentClearanceRequest(BaseModel):
    student_id: str

class ClearanceStatus(BaseModel):
    department_id: str
    status: str
    comments: Optional[str] = None

class CertificateRequest(BaseModel):
    student_id: str
    programme_id: str
    issue_date: str
    authorized_by: str  # User ID of the person authorizing

class FeeUpdate(BaseModel):
    student_id: str
    academic_year: int
    semester: int
    total_fees_due: float
    total_fees_paid: float

# ============= CLEARANCE CHECK FUNCTIONS =============

def check_financial_clearance(student_id: str):
    """Check if student has cleared all fees"""
    conn = get_db()
    if not conn:
        return {"cleared": False, "message": "Database unavailable"}
    
    cur = conn.cursor()
    cur.execute("""
        SELECT 
            SUM(total_fees_due) as total_due,
            SUM(total_fees_paid) as total_paid,
            SUM(balance) as total_balance
        FROM financial_clearance
        WHERE student_id = %s
    """, (student_id,))
    
    result = cur.fetchone()
    cur.close()
    conn.close()
    
    if not result or result[2] is None:
        # No financial records - assume cleared
        return {"cleared": True, "balance": 0, "message": "No outstanding fees"}
    
    total_balance = float(result[2]) if result[2] else 0
    return {
        "cleared": total_balance <= 0,
        "balance": total_balance,
        "total_due": float(result[0]) if result[0] else 0,
        "total_paid": float(result[1]) if result[1] else 0,
        "message": "Fully cleared" if total_balance <= 0 else f"Balance: {total_balance}"
    }

def check_academic_clearance(student_id: str):
    """Check if student has completed all academic requirements"""
    conn = get_db()
    if not conn:
        return {"cleared": False, "message": "Database unavailable"}
    
    cur = conn.cursor()
    cur.execute("""
        SELECT 
            total_credits_required,
            total_credits_earned,
            total_credits_remaining,
            courses_remaining,
            is_eligible_for_graduation
        FROM student_academic_status
        WHERE student_id = %s
    """, (student_id,))
    
    result = cur.fetchone()
    cur.close()
    conn.close()
    
    if not result:
        return {"cleared": False, "message": "No academic records found"}
    
    return {
        "cleared": result[4],  # is_eligible_for_graduation
        "credits_required": result[0],
        "credits_earned": result[1],
        "credits_remaining": result[2],
        "courses_remaining": result[3],
        "message": "Academic requirements met" if result[4] else f"{result[3]} courses remaining"
    }

def check_department_clearance(student_id: str, department_code: str):
    """Check clearance from a specific department"""
    conn = get_db()
    if not conn:
        return {"cleared": False, "message": "Database unavailable"}
    
    cur = conn.cursor()
    cur.execute("""
        SELECT sc.status, sc.comments, cd.name
        FROM student_clearance sc
        JOIN clearance_departments cd ON sc.department_id = cd.department_id
        WHERE sc.student_id = %s AND cd.code = %s
    """, (student_id, department_code))
    
    result = cur.fetchone()
    cur.close()
    conn.close()
    
    if not result:
        return {"cleared": False, "message": f"No clearance record for {department_code}"}
    
    return {
        "cleared": result[0] == 'CLEARED',
        "status": result[0],
        "comments": result[1],
        "department": result[2]
    }

def check_full_clearance(student_id: str):
    """Check all clearance requirements"""
    departments = ['FINANCE', 'ACADEMIC', 'LIBRARY', 'ACCOMMODATION', 'DISCIPLINE', 'REGISTRY']
    results = {}
    all_cleared = True
    
    for dept in departments:
        if dept == 'FINANCE':
            result = check_financial_clearance(student_id)
            results[dept] = result
            if not result.get('cleared', False):
                all_cleared = False
        elif dept == 'ACADEMIC':
            result = check_academic_clearance(student_id)
            results[dept] = result
            if not result.get('cleared', False):
                all_cleared = False
        else:
            result = check_department_clearance(student_id, dept)
            results[dept] = result
            if not result.get('cleared', False):
                all_cleared = False
    
    return {
        "student_id": student_id,
        "all_cleared": all_cleared,
        "departments": results,
        "timestamp": datetime.now().isoformat()
    }

# ============= API ENDPOINTS =============

@app.get("/")
async def root():
    return {
        "message": "Certificate Service with Clearance",
        "version": "2.0.0",
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

@app.post("/students/clearance")
async def get_student_clearance(request: StudentClearanceRequest):
    """Get full clearance status for a student"""
    try:
        result = check_full_clearance(request.student_id)
        return result
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/students/financial")
async def update_financial_clearance(fee: FeeUpdate):
    """Update financial clearance for a student"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        balance = fee.total_fees_due - fee.total_fees_paid
        is_cleared = balance <= 0
        
        cur.execute("""
            INSERT INTO financial_clearance (
                student_id, academic_year, semester,
                total_fees_due, total_fees_paid, balance, is_cleared
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (student_id, academic_year, semester)
            DO UPDATE SET
                total_fees_due = EXCLUDED.total_fees_due,
                total_fees_paid = EXCLUDED.total_fees_paid,
                balance = EXCLUDED.balance,
                is_cleared = EXCLUDED.is_cleared,
                last_updated = CURRENT_TIMESTAMP
        """, (
            fee.student_id, fee.academic_year, fee.semester,
            fee.total_fees_due, fee.total_fees_paid, balance, is_cleared
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {
            "student_id": fee.student_id,
            "balance": balance,
            "is_cleared": is_cleared,
            "message": "Financial clearance updated"
        }
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/departments/clear")
async def clear_department(request: dict):
    """Clear a student for a specific department"""
    try:
        student_id = request.get('student_id')
        department_code = request.get('department_code')
        cleared_by = request.get('cleared_by')
        comments = request.get('comments', '')
        
        if not student_id or not department_code or not cleared_by:
            raise HTTPException(status_code=400, detail="Missing required fields")
        
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Get department_id
        cur.execute("SELECT department_id FROM clearance_departments WHERE code = %s", (department_code,))
        dept_result = cur.fetchone()
        if not dept_result:
            cur.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Department not found")
        
        department_id = dept_result[0]
        
        # Update clearance
        cur.execute("""
            INSERT INTO student_clearance (student_id, department_id, status, cleared_by, cleared_at, comments)
            VALUES (%s, %s, 'CLEARED', %s, CURRENT_TIMESTAMP, %s)
            ON CONFLICT (student_id, department_id)
            DO UPDATE SET
                status = 'CLEARED',
                cleared_by = EXCLUDED.cleared_by,
                cleared_at = CURRENT_TIMESTAMP,
                comments = EXCLUDED.comments,
                updated_at = CURRENT_TIMESTAMP
        """, (student_id, department_id, cleared_by, comments))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {
            "student_id": student_id,
            "department": department_code,
            "status": "CLEARED",
            "cleared_by": cleared_by,
            "message": f"Student cleared by {department_code}"
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/check")
async def check_certificate_eligibility(request: CertificateRequest):
    """Check if a student is eligible for certificate issuance"""
    try:
        # Check full clearance
        clearance = check_full_clearance(request.student_id)
        
        if not clearance['all_cleared']:
            return {
                "eligible": False,
                "message": "Student is not cleared for certificate issuance",
                "clearance_status": clearance,
                "timestamp": datetime.now().isoformat()
            }
        
        return {
            "eligible": True,
            "message": "Student is eligible for certificate issuance",
            "clearance_status": clearance,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates")
async def create_certificate_with_clearance(request: CertificateRequest):
    """Create a certificate only if student is fully cleared"""
    try:
        # Check clearance
        clearance = check_full_clearance(request.student_id)
        
        if not clearance['all_cleared']:
            raise HTTPException(
                status_code=403,
                detail={
                    "message": "Student not cleared for certificate",
                    "clearance": clearance
                }
            )
        
        # Generate certificate
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
        """, (cert_id, cert_num, verify_code, request.student_id, request.programme_id, request.issue_date, 'ISSUED'))
        
        conn.commit()
        cur.close()
        conn.close()
        
        # Log certificate issuance with authorization
        # (In a real system, you'd have an audit log)
        
        return {
            "certificate_id": cert_id,
            "certificate_number": cert_num,
            "verification_code": verify_code,
            "status": "ISSUED",
            "issue_date": request.issue_date,
            "authorized_by": request.authorized_by,
            "clearance_verified": True,
            "message": "Certificate issued with full clearance"
        }
        
    except HTTPException:
        raise
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

if __name__ == "__main__":
    import uvicorn
    print("Starting uvicorn server with clearance...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8000)
