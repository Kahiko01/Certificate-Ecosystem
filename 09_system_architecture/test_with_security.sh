#!/bin/bash

echo "========================================="
echo "Testing Certificate System with Security"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Register a user
echo -e "\n${YELLOW}[1] Register New User${NC}"
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice_smith",
    "email": "alice@university.ac.ke",
    "password": "SecurePass123!",
    "first_name": "Alice",
    "last_name": "Smith"
  }')

echo $REGISTER_RESPONSE | python3 -m json.tool

# 2. Login
echo -e "\n${YELLOW}[2] Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice_smith",
    "password": "SecurePass123!"
  }')

echo $LOGIN_RESPONSE | python3 -m json.tool

# Extract token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "${RED}Failed to get access token${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token acquired: ${ACCESS_TOKEN:0:20}...${NC}"

# 3. Create a signed certificate
echo -e "\n${YELLOW}[3] Create Signed Certificate${NC}"
SIGNED_RESPONSE=$(curl -s -X POST http://localhost:8000/certificates/signed \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28"
  }')

echo $SIGNED_RESPONSE | python3 -m json.tool

# Extract certificate ID
CERT_ID=$(echo $SIGNED_RESPONSE | grep -o '"certificate_id":"[^"]*"' | cut -d'"' -f4)

# 4. Verify the signature
if [ ! -z "$CERT_ID" ]; then
  echo -e "\n${YELLOW}[4] Verify Certificate Signature${NC}"
  curl -s http://localhost:8000/verify/signature/$CERT_ID | python3 -m json.tool
fi

# 5. Try accessing protected route without token
echo -e "\n${YELLOW}[5] Access Protected Route Without Token${NC}"
curl -s http://localhost:8000/protected | python3 -m json.tool

# 6. Access protected route with token
echo -e "\n${YELLOW}[6] Access Protected Route With Token${NC}"
curl -s http://localhost:8000/protected \
  -H "Authorization: Bearer $ACCESS_TOKEN" | python3 -m json.tool

echo -e "\n${GREEN}========================================="
echo "Security Tests Complete! ✅"
echo "=========================================${NC}"
