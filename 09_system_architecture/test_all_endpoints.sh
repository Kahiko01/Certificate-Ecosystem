#!/bin/bash

echo "========================================="
echo "Testing All Certificate API Endpoints"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Root endpoint
echo -e "\n${YELLOW}[1] Root Endpoint${NC}"
curl -s http://localhost:8000/ | python3 -m json.tool

# 2. Health check
echo -e "\n${YELLOW}[2] Health Check${NC}"
curl -s http://localhost:8000/health | python3 -m json.tool

# 3. List certificates
echo -e "\n${YELLOW}[3] List Certificates${NC}"
curl -s "http://localhost:8000/certificates?limit=3" | python3 -m json.tool

# 4. Create a certificate
echo -e "\n${YELLOW}[4] Create Certificate${NC}"
RESPONSE=$(curl -s -X POST http://localhost:8000/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28"
  }')

echo $RESPONSE | python3 -m json.tool
CERT_ID=$(echo $RESPONSE | grep -o '"certificate_id":"[^"]*"' | cut -d'"' -f4)
VERIFY_CODE=$(echo $RESPONSE | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)

# 5. Get certificate by ID
if [ ! -z "$CERT_ID" ]; then
  echo -e "\n${YELLOW}[5] Get Certificate by ID${NC}"
  curl -s http://localhost:8000/certificates/$CERT_ID | python3 -m json.tool
fi

# 6. Verify certificate
if [ ! -z "$VERIFY_CODE" ]; then
  echo -e "\n${YELLOW}[6] Verify Certificate${NC}"
  curl -s http://localhost:8000/verify/$VERIFY_CODE | python3 -m json.tool
fi

# 7. Get student certificates
echo -e "\n${YELLOW}[7] Get Student Certificates${NC}"
curl -s "http://localhost:8000/students/550e8400-e29b-41d4-a716-446655440001/certificates" | python3 -m json.tool

# 8. System stats
echo -e "\n${YELLOW}[8] System Statistics${NC}"
curl -s http://localhost:8000/stats | python3 -m json.tool

echo -e "\n${GREEN}========================================="
echo "All Tests Complete! ✅"
echo "=========================================${NC}"
