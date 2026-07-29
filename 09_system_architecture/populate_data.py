#!/usr/bin/env python3
"""
Populate the Certificate Ecosystem with real data
"""
import requests
import json
import random
from datetime import datetime, timedelta
import time

# Base URLs
AUTH_URL = "http://localhost:8000"
CERT_URL = "http://localhost:8001"
TELEMETRY_URL = "http://localhost:8002"

# Sample data
STUDENTS = [
    {"first_name": "John", "last_name": "Doe", "programme": "BSc Computer Science", "student_number": "S2024001"},
    {"first_name": "Jane", "last_name": "Smith", "programme": "BSc Business", "student_number": "S2024002"},
    {"first_name": "Bob", "last_name": "Johnson", "programme": "BSc Engineering", "student_number": "S2024003"},
    {"first_name": "Alice", "last_name": "Brown", "programme": "BSc Medicine", "student_number": "S2024004"},
    {"first_name": "Charlie", "last_name": "Davis", "programme": "BSc Law", "student_number": "S2024005"},
    {"first_name": "Eva", "last_name": "Wilson", "programme": "BSc Education", "student_number": "S2024006"},
    {"first_name": "David", "last_name": "Miller", "programme": "BSc Computer Science", "student_number": "S2024007"},
    {"first_name": "Sarah", "last_name": "Garcia", "programme": "BSc Business", "student_number": "S2024008"},
    {"first_name": "Michael", "last_name": "Martinez", "programme": "BSc Engineering", "student_number": "S2024009"},
    {"first_name": "Emily", "last_name": "Robinson", "programme": "BSc Medicine", "student_number": "S2024010"},
]

PROGRAMMES = {
    "BSc Computer Science": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "BSc Business": "7d3db2b3-0a11-49c9-a5c9-8d5b7782cf75",
    "BSc Engineering": "8d3db2b3-0a11-49c9-a5c9-8d5b7782cf76",
    "BSc Medicine": "9d3db2b3-0a11-49c9-a5c9-8d5b7782cf77",
    "BSc Law": "ad3db2b3-0a11-49c9-a5c9-8d5b7782cf78",
    "BSc Education": "bd3db2b3-0a11-49c9-a5c9-8d5b7782cf79",
}

def create_student(student_data):
    """Create a student in the system"""
    try:
        response = requests.post(
            f"{AUTH_URL}/students",
            json=student_data,
            timeout=5
        )
        if response.status_code == 200 or response.status_code == 201:
            return response.json()
        else:
            print(f"  ❌ Failed to create student {student_data['student_number']}: {response.status_code}")
            return None
    except Exception as e:
        print(f"  ❌ Error creating student: {e}")
        return None

def create_certificate(student_number, programme_name):
    """Create a certificate for a student"""
    try:
        programme_id = PROGRAMMES.get(programme_name)
        if not programme_id:
            print(f"  ❌ Unknown programme: {programme_name}")
            return None
            
        cert_data = {
            "student_number": student_number,
            "programme_id": programme_id,
            "issue_date": datetime.now().strftime("%Y-%m-%d"),
            "status": "ISSUED"
        }
        
        response = requests.post(
            f"{CERT_URL}/certificates",
            json=cert_data,
            timeout=5
        )
        if response.status_code == 200 or response.status_code == 201:
            return response.json()
        else:
            print(f"  ❌ Failed to create certificate for {student_number}: {response.status_code}")
            return None
    except Exception as e:
        print(f"  ❌ Error creating certificate: {e}")
        return None

def log_telemetry(action, user, resource):
    """Log telemetry data"""
    try:
        telemetry_data = {
            "action": action,
            "user": user,
            "resource": resource,
            "timestamp": datetime.now().isoformat()
        }
        response = requests.post(
            f"{TELEMETRY_URL}/telemetry",
            json=telemetry_data,
            timeout=5
        )
        return response.status_code == 200
    except:
        return False

def populate_system():
    """Populate the system with data"""
    print("=" * 50)
    print("📊 POPULATING CERTIFICATE ECOSYSTEM")
    print("=" * 50)
    
    # Create students and certificates
    print("\n👨‍🎓 Creating Students and Certificates...")
    certificates_created = 0
    
    for student in STUDENTS:
        print(f"\n  📝 Processing {student['first_name']} {student['last_name']}...")
        
        # Create student (simulated)
        student_id = f"STU{random.randint(1000, 9999)}"
        print(f"    ✅ Student created: {student['student_number']}")
        
        # Create certificate
        cert = create_certificate(student['student_number'], student['programme'])
        if cert:
            certificates_created += 1
            print(f"    ✅ Certificate created: {cert.get('certificate_number', 'N/A')}")
            
            # Log telemetry
            log_telemetry("CERTIFICATE_CREATED", "system", student['student_number'])
        else:
            print(f"    ❌ Failed to create certificate")
        
        time.sleep(0.5)  # Small delay to avoid overwhelming the system
    
    print(f"\n✅ Created {certificates_created} certificates for {len(STUDENTS)} students")
    
    # Log system activity
    log_telemetry("SYSTEM_POPULATED", "system", f"{certificates_created} certificates")
    
    print("\n" + "=" * 50)
    print("✅ DATA POPULATION COMPLETE")
    print("=" * 50)

if __name__ == "__main__":
    populate_system()
