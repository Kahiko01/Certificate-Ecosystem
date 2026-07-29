import psycopg2
import hashlib
import secrets

def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    return salt + ":" + hashlib.sha256((salt + password).encode()).hexdigest()

# Connect to database
conn = psycopg2.connect(
    host="certificate-postgres",
    database="certificate_ecosystem",
    user="cert_admin",
    password="secure_password_123"
)

cur = conn.cursor()

# Update system admin password
cur.execute("""
    UPDATE users 
    SET password_hash = %s 
    WHERE username = 'system_admin'
""", (hash_password('admin_hash'),))

# Update all department heads with default_hash
cur.execute("""
    UPDATE users 
    SET password_hash = %s 
    WHERE username IN ('registrar', 'finance_head', 'academic_head', 
                       'library_head', 'accommodation_head', 'discipline_head', 
                       'registry_head', 'senate_head', 'finance_officer', 
                       'academic_officer', 'library_officer', 'accommodation_officer', 
                       'discipline_officer', 'registry_officer', 'senate_officer')
""", (hash_password('default_hash'),))

conn.commit()
cur.close()
conn.close()

print("✅ Passwords reset successfully!")
print("system_admin -> admin_hash")
print("All department users -> default_hash")
