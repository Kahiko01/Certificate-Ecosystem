#!/bin/bash

echo "========================================="
echo "Testing Certificate API"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get container IP
CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' certificate-service)
BASE_URL="http://$CONTAINER_IP:8000"

echo -e "\n${YELLOW}Container IP: $CONTAINER_IP${NC}"

# 1. Health check
echo -e "\n${YELLOW}[1] Health Check${NC}"
curl -s $BASE_URL/health | python3 -m json.tool

# 2. List certificates
echo -e "\n${YELLOW}[2] List Certificates${NC}"
curl -s $BASE_URL/certificates | python3 -m json.tool

# 3. Create certificate
echo -e "\n${YELLOW}[3] Create Certificate${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "2026-07-28"
  }')

echo $RESPONSE | python3 -m json.tool

# Extract verification code
VERIFY_CODE=$(echo $RESPONSE | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$VERIFY_CODE" ]; then
  echo -e "\n${GREEN}✓ Certificate created${NC}"
  echo -e "\n${YELLOW}[4] Verify Certificate${NC}"
  curl -s $BASE_URL/verify/$VERIFY_CODE | python3 -m json.tool
else
  echo -e "\n${RED}✗ Failed to create certificate${NC}"
fi

echo -e "\n${GREEN}========================================="
echo "Test Complete!"
echo "=========================================${NC}"
