#!/bin/bash

echo "========================================="
echo "Working Certificate Ecosystem Test"
echo "========================================="

# 1. Insert student data
echo -e "\n[1] Inserting student data..."
sudo docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem << 'SQL'
INSERT INTO users (user_id, username, email, password_hash, first_name, last_name)
VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'john_doe', 'john.doe@university.ac.ke', 'hashed_password', 'John', 'Doe')
ON CONFLICT (username) DO NOTHING;

INSERT INTO students (student_id, user_id, student_number, admission_date, current_status, mode_of_study)
VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 'S2024001', '2024-09-01', 'ACTIVE', 'FULL_TIME')
ON CONFLICT (student_number) DO NOTHING;

SELECT 'Student created successfully!' as status;
SQL

# 2. Create certificate
echo -e "\n[2] Creating certificate..."
RESPONSE=$(curl -s -X POST http://localhost:8000/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28"
  }')

echo $RESPONSE | python3 -m json.tool

# Extract values
CERT_ID=$(echo $RESPONSE | grep -o '"certificate_id":"[^"]*"' | cut -d'"' -f4)
VERIFY_CODE=$(echo $RESPONSE | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)
CERT_NUM=$(echo $RESPONSE | grep -o '"certificate_number":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$CERT_ID" ]; then
  echo -e "\n✅ Certificate created successfully!"
  echo "   Certificate ID: $CERT_ID"
  echo "   Certificate Number: $CERT_NUM"
  echo "   Verification Code: $VERIFY_CODE"
else
  echo -e "\n❌ Failed to create certificate"
  exit 1
fi

# 3. Get certificate by ID
echo -e "\n[3] Retrieving certificate by ID..."
curl -s http://localhost:8000/certificates/$CERT_ID | python3 -m json.tool

# 4. Verify certificate
echo -e "\n[4] Verifying certificate..."
curl -s http://localhost:8000/verify/$VERIFY_CODE | python3 -m json.tool

# 5. Show database summary
echo -e "\n[5] Database summary:"
sudo docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem << 'SQL'
SELECT 
    c.certificate_number,
    c.verification_code,
    c.status,
    c.issue_date,
    s.student_number,
    u.first_name || ' ' || u.last_name as student_name
FROM certificates c
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
ORDER BY c.created_at DESC
LIMIT 5;
SQL

echo -e "\n========================================="
echo "✅ Test Complete!"
echo "========================================="
