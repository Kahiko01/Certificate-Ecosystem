#!/bin/bash

echo "Setting up test clearance data..."

# 1. Clear all departments for a student
for dept in FINANCE ACADEMIC LIBRARY ACCOMMODATION DISCIPLINE REGISTRY SENATE; do
    curl -s -X POST http://localhost:8000/departments/clear \
      -H "Content-Type: application/json" \
      -d "{
        \"student_id\": \"550e8400-e29b-41d4-a716-446655440001\",
        \"department_code\": \"$dept\",
        \"cleared_by\": \"550e8400-e29b-41d4-a716-446655440000\",
        \"comments\": \"Cleared by test script\"
      }" > /dev/null
    echo "Cleared $dept"
done

# 2. Check clearance status
echo -e "\nFinal Clearance Status:"
curl -s -X POST http://localhost:8000/students/clearance \
  -H "Content-Type: application/json" \
  -d '{"student_id": "550e8400-e29b-41d4-a716-446655440001"}' | python3 -m json.tool

# 3. Check certificate eligibility
echo -e "\nCertificate Eligibility:"
curl -s -X POST http://localhost:8000/certificates/check \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28",
    "authorized_by": "550e8400-e29b-41d4-a716-446655440000"
  }' | python3 -m json.tool

# 4. Issue a certificate with clearance
echo -e "\nIssuing Certificate with Clearance:"
curl -s -X POST http://localhost:8000/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28",
    "authorized_by": "550e8400-e29b-41d4-a716-446655440000"
  }' | python3 -m json.tool
