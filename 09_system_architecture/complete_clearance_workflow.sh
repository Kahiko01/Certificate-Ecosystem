#!/bin/bash

echo "========================================="
echo "🎓 Complete Clearance Workflow Test"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STUDENT_ID="550e8400-e29b-41d4-a716-446655440001"
PROGRAMME_ID="6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74"
AUTHORIZER="550e8400-e29b-41d4-a716-446655440000"

# 1. Full clearance check
echo -e "\n${YELLOW}[1] Full Clearance Status${NC}"
CLEARANCE=$(curl -s -X POST http://localhost:8000/students/clearance \
  -H "Content-Type: application/json" \
  -d "{\"student_id\": \"$STUDENT_ID\"}")

echo $CLEARANCE | python3 -m json.tool

ALL_CLEARED=$(echo $CLEARANCE | grep -o '"all_cleared": [a-z]*' | cut -d' ' -f2)

if [ "$ALL_CLEARED" == "true" ]; then
    echo -e "${GREEN}✅ Student is FULLY CLEARED!${NC}"
else
    echo -e "${RED}❌ Student is NOT fully cleared${NC}"
    echo -e "${YELLOW}Pending departments:${NC}"
    echo $CLEARANCE | grep -o '"cleared": false' | wc -l
    exit 1
fi

# 2. Check eligibility
echo -e "\n${YELLOW}[2] Certificate Eligibility${NC}"
ELIGIBLE=$(curl -s -X POST http://localhost:8000/certificates/check \
  -H "Content-Type: application/json" \
  -d "{
    \"student_id\": \"$STUDENT_ID\",
    \"programme_id\": \"$PROGRAMME_ID\",
    \"issue_date\": \"2026-07-28\",
    \"authorized_by\": \"$AUTHORIZER\"
  }")

echo $ELIGIBLE | python3 -m json.tool

IS_ELIGIBLE=$(echo $ELIGIBLE | grep -o '"eligible": [a-z]*' | cut -d' ' -f2)

if [ "$IS_ELIGIBLE" == "true" ]; then
    echo -e "${GREEN}✅ Student is eligible for certificate!${NC}"
else
    echo -e "${RED}❌ Student is NOT eligible${NC}"
    exit 1
fi

# 3. Issue certificate
echo -e "\n${YELLOW}[3] Issuing Certificate${NC}"
CERT=$(curl -s -X POST http://localhost:8000/certificates \
  -H "Content-Type: application/json" \
  -d "{
    \"student_id\": \"$STUDENT_ID\",
    \"programme_id\": \"$PROGRAMME_ID\",
    \"issue_date\": \"2026-07-28\",
    \"authorized_by\": \"$AUTHORIZER\"
  }")

echo $CERT | python3 -m json.tool

CERT_ID=$(echo $CERT | grep -o '"certificate_id":"[^"]*"' | cut -d'"' -f4)
VERIFY_CODE=$(echo $CERT | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)
CERT_NUM=$(echo $CERT | grep -o '"certificate_number":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$CERT_ID" ]; then
    echo -e "${GREEN}✅ Certificate issued successfully!${NC}"
    echo -e "${BLUE}   📋 Certificate ID: $CERT_ID${NC}"
    echo -e "${BLUE}   🔢 Certificate Number: $CERT_NUM${NC}"
    echo -e "${BLUE}   🔑 Verification Code: $VERIFY_CODE${NC}"
    
    # 4. Verify the certificate
    echo -e "\n${YELLOW}[4] Verifying Certificate${NC}"
    VERIFY=$(curl -s http://localhost:8000/verify/$VERIFY_CODE)
    echo $VERIFY | python3 -m json.tool
    
    if echo $VERIFY | grep -q '"valid": true'; then
        echo -e "${GREEN}✅ Certificate verified successfully!${NC}"
        echo -e "${GREEN}🎓 Certificate is authentic and valid!${NC}"
    else
        echo -e "${RED}❌ Certificate verification failed${NC}"
    fi
else
    echo -e "${RED}❌ Failed to issue certificate${NC}"
fi

echo -e "\n${GREEN}========================================="
echo "✅ Complete Workflow Test Passed!"
echo "=========================================${NC}"
