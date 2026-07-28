import hashlib
import json
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization
import secrets

class DigitalSignature:
    def __init__(self):
        # In production, load from secure key store
        self.private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048
        )
        self.public_key = self.private_key.public_key()
    
    def sign_certificate(self, certificate_data: dict) -> str:
        """Sign certificate data"""
        # Convert to JSON and hash
        data_string = json.dumps(certificate_data, sort_keys=True)
        data_bytes = data_string.encode('utf-8')
        
        # Sign
        signature = self.private_key.sign(
            data_bytes,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        
        # Encode as base64
        return base64.b64encode(signature).decode('utf-8')
    
    def verify_signature(self, certificate_data: dict, signature: str) -> bool:
        """Verify certificate signature"""
        try:
            data_string = json.dumps(certificate_data, sort_keys=True)
            data_bytes = data_string.encode('utf-8')
            signature_bytes = base64.b64decode(signature)
            
            # Verify
            self.public_key.verify(
                signature_bytes,
                data_bytes,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False
    
    def get_public_key_pem(self) -> str:
        """Get public key in PEM format"""
        return self.public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ).decode('utf-8')

# Create a global instance
signer = DigitalSignature()

# Add to certificate service
cat >> certificate_service.py << 'EOF'

# Import digital signature
from digital_signature import signer

# Update create_certificate to include digital signature
@app.post("/certificates/signed")
async def create_signed_certificate(cert: CertificateCreate, current_user: dict = Depends(get_current_user)):
    """Create a digitally signed certificate"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Generate certificate
        certificate_id = str(uuid.uuid4())
        certificate_number = f"CERT-{datetime.now().year}-{str(uuid.uuid4())[:8].upper()}"
        verification_code = str(uuid.uuid4())[:8].upper()
        
        certificate_data = {
            "certificate_id": certificate_id,
            "certificate_number": certificate_number,
            "verification_code": verification_code,
            "student_id": cert.student_id,
            "programme_id": cert.programme_id,
            "issue_date": cert.issue_date,
            "status": "ISSUED"
        }
        
        # Create digital signature
        signature = signer.sign_certificate(certificate_data)
        
        # Insert into database with signature
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
        
        # Return certificate with signature
        certificate_data["digital_signature"] = signature
        
        return certificate_data
        
    except Exception as e:
        print(f"Error creating signed certificate: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/verify/signature/{certificate_id}")
async def verify_certificate_signature(certificate_id: str):
    """Verify a certificate's digital signature"""
    try:
        # Get certificate data
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT certificate_number, verification_code, student_id, programme_id, issue_date, status
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
            "student_id": result[2],
            "programme_id": result[3],
            "issue_date": str(result[4]),
            "status": result[5]
        }
        
        # In a real system, you'd store the signature and verify it
        # For demo purposes, we'll just show the public key
        return {
            "certificate": certificate_data,
            "public_key": signer.get_public_key_pem(),
            "verification_info": "Use the public key to verify the certificate signature"
        }
        
    except Exception as e:
        print(f"Error verifying signature: {e}")
        raise HTTPException(status_code=500, detail=str(e))
