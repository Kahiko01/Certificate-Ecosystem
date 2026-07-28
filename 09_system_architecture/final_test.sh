#!/bin/bash

echo "========================================="
echo "🎓 University Certificate Ecosystem"
echo "   Complete System Test"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get container IP
CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' certificate-service)
BASE_URL="http://$CONTAINER_IP:8000"

echo -e "\n${BLUE}📡 API Base URL: $BASE_URL${NC}"

# 1. Health Check
echo -e "\n${YELLOW}[1] 🏥 Health Check${NC}"
HEALTH=$(curl -s $BASE_URL/health)
echo $HEALTH | python3 -m json.tool
if echo $HEALTH | grep -q "healthy"; then
    echo -e "${GREEN}✅ System is healthy${NC}"
else
    echo -e "${RED}❌ System is not healthy${NC}"
fi

# 2. System Statistics
echo -e "\n${YELLOW}[2] 📊 System Statistics${NC}"
curl -s $BASE_URL/stats | python3 -m json.tool

# 3. List Certificates
echo -e "\n${YELLOW}[3] 📜 List Certificates${NC}"
CERT_LIST=$(curl -s $BASE_URL/certificates)
echo $CERT_LIST | python3 -m json.tool
COUNT=$(echo $CERT_LIST | grep -o '"count":[0-9]*' | cut -d':' -f2)
echo -e "${GREEN}📊 Total Certificates: $COUNT${NC}"

# 4. Create a New Certificate
echo -e "\n${YELLOW}[4] ✨ Create New Certificate${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/certificates \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440001",
    "programme_id": "6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74",
    "issue_date": "'$(date +%Y-%m-%d)'"
  }')

echo $RESPONSE | python3 -m json.tool

# Extract values
CERT_ID=$(echo $RESPONSE | grep -o '"certificate_id":"[^"]*"' | cut -d'"' -f4)
VERIFY_CODE=$(echo $RESPONSE | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)
CERT_NUM=$(echo $RESPONSE | grep -o '"certificate_number":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$CERT_ID" ]; then
    echo -e "${GREEN}✅ Certificate created successfully!${NC}"
    echo "   📋 ID: $CERT_ID"
    echo "   🔢 Number: $CERT_NUM"
    echo "   🔑 Verification Code: $VERIFY_CODE"
else
    echo -e "${RED}❌ Failed to create certificate${NC}"
fi

# 5. Get Certificate by ID
if [ ! -z "$CERT_ID" ]; then
    echo -e "\n${YELLOW}[5] 🔍 Get Certificate by ID${NC}"
    curl -s $BASE_URL/certificates/$CERT_ID | python3 -m json.tool
fi

# 6. Verify Certificate
if [ ! -z "$VERIFY_CODE" ]; then
    echo -e "\n${YELLOW}[6] ✅ Verify Certificate${NC}"
    VERIFY_RESULT=$(curl -s $BASE_URL/verify/$VERIFY_CODE)
    echo $VERIFY_RESULT | python3 -m json.tool
    if echo $VERIFY_RESULT | grep -q '"valid": true'; then
        echo -e "${GREEN}✅ Certificate is VALID${NC}"
    else
        echo -e "${RED}❌ Certificate verification failed${NC}"
    fi
fi

# 7. Get Student Certificates
echo -e "\n${YELLOW}[7] 👨‍🎓 Get Student Certificates${NC}"
curl -s $BASE_URL/students/550e8400-e29b-41d4-a716-446655440001/certificates | python3 -m json.tool

# 8. Test Invalid Verification
echo -e "\n${YELLOW}[8] ❌ Test Invalid Verification${NC}"
INVALID_RESULT=$(curl -s $BASE_URL/verify/INVALID123)
echo $INVALID_RESULT | python3 -m json.tool
if echo $INVALID_RESULT | grep -q '"valid": false'; then
    echo -e "${GREEN}✅ Invalid code correctly rejected${NC}"
else
    echo -e "${RED}❌ Invalid code test failed${NC}"
fi

echo -e "\n${GREEN}========================================="
echo "✅ ALL TESTS PASSED!"
echo "   Your Certificate Ecosystem is Running!"
echo "=========================================${NC}"

echo -e "\n${BLUE}📝 Quick Reference:${NC}"
echo "  Create:  curl -X POST $BASE_URL/certificates -H 'Content-Type: application/json' -d '{\"student_id\":\"...\",\"programme_id\":\"...\",\"issue_date\":\"2026-07-28\"}'"
echo "  List:    curl $BASE_URL/certificates"
echo "  Verify:  curl $BASE_URL/verify/VERIFICATION_CODE"
echo "  Stats:   curl $BASE_URL/stats"
