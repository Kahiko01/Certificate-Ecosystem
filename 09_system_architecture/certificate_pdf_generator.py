"""
Certificate PDF Generator Service
Generates beautiful PDF certificates with university branding
"""
from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
import uuid
import json
from datetime import datetime
import sys
import os
import io
import base64
import random
import string
import jwt

# PDF generation libraries
from reportlab.lib.pagesizes import A4, landscape
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.graphics.shapes import Drawing
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.pdfgen import canvas

app = FastAPI(title="Certificate PDF Generator")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "your-super-secret-key-change-in-production"
ALGORITHM = "HS256"

print("Starting Certificate PDF Generator...", file=sys.stderr, flush=True)

# ===== AUTHENTICATION =====
def verify_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(authorization: str = Header(...)):
    try:
        token = authorization.replace("Bearer ", "")
        return verify_token(token)
    except:
        raise HTTPException(status_code=401, detail="Invalid authentication")

def is_authorized(user: dict) -> bool:
    user_role = user.get('role', '')
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
class CertificatePDFRequest(BaseModel):
    certificate_id: str

class CertificateGenerateRequest(BaseModel):
    student_id: str
    student_name: str
    programme: str
    honours: str = "First Class Honours"
    graduation_date: str
    registrar_name: str = "Dr. Sarah Johnson"
    vice_chancellor_name: str = "Prof. Michael Brown"
    dean_name: str = "Prof. Alice Smith"

# ===== PDF GENERATION =====
def generate_certificate_number():
    year = datetime.now().year
    num = str(random.randint(1, 999999)).zfill(6)
    return f"CU/{year}/BCom/{num}"

def generate_verification_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

def create_certificate_pdf(student_data, certificate_data):
    """Generate a beautiful PDF certificate"""
    
    # Create certificates directory
    os.makedirs("certificates", exist_ok=True)
    
    filename = f"certificates/certificate_{certificate_data['certificate_number']}.pdf"
    
    # Create PDF
    doc = SimpleDocTemplate(
        filename,
        pagesize=landscape(A4),
        rightMargin=72,
        leftMargin=72,
        topMargin=72,
        bottomMargin=72
    )
    
    # Styles
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=28,
        textColor=colors.darkblue,
        alignment=1,
        spaceAfter=20,
        fontName='Helvetica-Bold'
    )
    
    subtitle_style = ParagraphStyle(
        'CustomSubtitle',
        parent=styles['Heading2'],
        fontSize=20,
        textColor=colors.darkblue,
        alignment=1,
        spaceAfter=15
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontSize=16,
        alignment=1,
        spaceAfter=10
    )
    
    name_style = ParagraphStyle(
        'NameStyle',
        parent=styles['Normal'],
        fontSize=36,
        textColor=colors.darkred,
        alignment=1,
        spaceAfter=15,
        fontName='Helvetica-Bold'
    )
    
    small_style = ParagraphStyle(
        'SmallStyle',
        parent=styles['Normal'],
        fontSize=12,
        alignment=1,
        textColor=colors.grey
    )
    
    # Build story
    story = []
    
    # Decorative border
    story.append(Spacer(1, 0.3*inch))
    
    # University Name
    story.append(Paragraph("UNIVERSITY OF TECHNOLOGY", title_style))
    story.append(Spacer(1, 0.1*inch))
    
    # Decorative line
    story.append(Paragraph("✦ ✦ ✦", subtitle_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Certificate Title
    story.append(Paragraph("CERTIFICATE OF GRADUATION", subtitle_style))
    story.append(Spacer(1, 0.3*inch))
    
    # Certificate body
    story.append(Paragraph("This is to certify that", body_style))
    story.append(Spacer(1, 0.1*inch))
    
    # Student Name (large)
    story.append(Paragraph(student_data['student_name'], name_style))
    story.append(Spacer(1, 0.1*inch))
    
    # Programme details
    story.append(Paragraph("has successfully completed the requirements for", body_style))
    story.append(Spacer(1, 0.05*inch))
    
    programme_style = ParagraphStyle(
        'ProgrammeStyle',
        parent=styles['Normal'],
        fontSize=20,
        alignment=1,
        spaceAfter=10,
        fontName='Helvetica-Bold',
        textColor=colors.darkblue
    )
    story.append(Paragraph(certificate_data['programme'], programme_style))
    story.append(Spacer(1, 0.05*inch))
    
    story.append(Paragraph(f"with {certificate_data['honours']}", body_style))
    story.append(Spacer(1, 0.3*inch))
    
    # Date
    story.append(Paragraph(f"Issued on: {certificate_data['issue_date']}", body_style))
    story.append(Spacer(1, 0.3*inch))
    
    # Verification information
    verification_style = ParagraphStyle(
        'VerificationStyle',
        parent=styles['Normal'],
        fontSize=11,
        alignment=1,
        textColor=colors.grey
    )
    story.append(Paragraph(f"Certificate Number: {certificate_data['certificate_number']}", verification_style))
    story.append(Paragraph(f"Verification Code: {certificate_data['verification_code']}", verification_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Signatures
    signature_data = [
        ["Registrar", "Vice Chancellor", "Dean"],
        [certificate_data.get('registrar_name', 'Dr. Sarah Johnson'), 
         certificate_data.get('vice_chancellor_name', 'Prof. Michael Brown'),
         certificate_data.get('dean_name', 'Prof. Alice Smith')]
    ]
    
    sig_table = Table(signature_data, colWidths=[2*inch, 2*inch, 2*inch])
    sig_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 10),
        ('FONTNAME', (0,1), (-1,1), 'Helvetica'),
        ('FONTSIZE', (0,1), (-1,1), 11),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.black),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    
    story.append(sig_table)
    story.append(Spacer(1, 0.1*inch))
    
    # Footer
    footer_style = ParagraphStyle(
        'FooterStyle',
        parent=styles['Normal'],
        fontSize=9,
        alignment=1,
        textColor=colors.grey
    )
    story.append(Paragraph("This certificate is digitally verified and can be authenticated online", footer_style))
    story.append(Paragraph("verify.university.ac.ke", footer_style))
    
    # Build PDF
    doc.build(story)
    
    return filename

# ===== API ENDPOINTS =====
@app.get("/")
async def root():
    return {"message": "Certificate PDF Generator", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "certificate-pdf", "timestamp": datetime.now().isoformat()}

@app.post("/certificates/pdf/generate")
async def generate_certificate_pdf(
    request: CertificateGenerateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Generate a certificate PDF - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403,
            detail="Unauthorized. Only Registry and System Admin can generate certificates."
        )
    
    try:
        # Generate certificate data
        cert_number = generate_certificate_number()
        verify_code = generate_verification_code()
        
        certificate_data = {
            "certificate_number": cert_number,
            "verification_code": verify_code,
            "programme": request.programme,
            "honours": request.honours,
            "issue_date": request.graduation_date,
            "registrar_name": request.registrar_name,
            "vice_chancellor_name": request.vice_chancellor_name,
            "dean_name": request.dean_name
        }
        
        student_data = {
            "student_id": request.student_id,
            "student_name": request.student_name
        }
        
        # Generate PDF
        pdf_path = create_certificate_pdf(student_data, certificate_data)
        
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
                request.student_id,
                request.graduation_date,
                "ISSUED"
            ))
            conn.commit()
            cur.close()
            conn.close()
        
        return {
            "success": True,
            "message": f"Certificate PDF generated for {request.student_name}",
            "pdf_path": pdf_path,
            "certificate_number": cert_number,
            "verification_code": verify_code,
            "download_url": f"/certificates/pdf/download/{cert_number}",
            "generated_by": current_user.get('sub', 'system')
        }
        
    except Exception as e:
        print(f"Error generating PDF: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/certificates/pdf/download/{cert_number}")
async def download_certificate_pdf(
    cert_number: str,
    current_user: dict = Depends(get_current_user)
):
    """Download a certificate PDF - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403,
            detail="Unauthorized. Only Registry and System Admin can download certificates."
        )
    
    try:
        pdf_path = f"certificates/certificate_{cert_number}.pdf"
        if not os.path.exists(pdf_path):
            raise HTTPException(status_code=404, detail="Certificate not found")
        
        return FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename=f"certificate_{cert_number}.pdf"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error downloading PDF: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/certificates/pdf/preview")
async def preview_certificate(
    request: CertificateGenerateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Preview a certificate PDF - REGISTRY & ADMIN ONLY"""
    if not is_authorized(current_user):
        raise HTTPException(
            status_code=403,
            detail="Unauthorized. Only Registry and System Admin can preview certificates."
        )
    
    try:
        # Generate certificate data
        cert_number = generate_certificate_number()
        verify_code = generate_verification_code()
        
        certificate_data = {
            "certificate_number": cert_number,
            "verification_code": verify_code,
            "programme": request.programme,
            "honours": request.honours,
            "issue_date": request.graduation_date,
            "registrar_name": request.registrar_name,
            "vice_chancellor_name": request.vice_chancellor_name,
            "dean_name": request.dean_name
        }
        
        student_data = {
            "student_id": request.student_id,
            "student_name": request.student_name
        }
        
        # Generate preview PDF
        pdf_path = create_certificate_pdf(student_data, certificate_data)
        
        return {
            "success": True,
            "message": "Certificate preview generated",
            "preview_url": f"/certificates/pdf/download/{cert_number}",
            "certificate_number": cert_number,
            "verification_code": verify_code
        }
        
    except Exception as e:
        print(f"Error generating preview: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Certificate PDF Generator on port 8006...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8006)
