#!/bin/bash

echo "========================================="
echo "Testing Full Clearance Workflow"
echo "========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STUDENT_ID="550e8400-e29b-41d4-a716-446655440001"
PROGRAMME_ID="6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74"
AUTHORIZER="550e8400-e29b-41d4-a716-446655440000"

# 1. Check initial clearance
echo -e "\n${YELLOW}[1] Initial Clearance Check${NC}"
INITIAL=$(curl -s -X POST http://localhost:8000/students/clearance \
  -H "Content-Type: application/json" \
  -d "{\"student_id\": \"$STUDENT_ID\"}")

echo $INITIAL | python3 -m json.tool
ALL_CLEARED=$(echo $INITIAL | grep -o '"all_cleared": [a-z]*' | cut -d' ' -f2)

if [ "$ALL_CLEARED" == "true" ]; then
    echo -e "${GREEN}✓ Student is fully cleared!${NC}"
else
    echo -e "${RED}✗ Student is NOT fully cleared${NC}"
    echo -e "${YELLOW}Check which departments are pending:${NC}"
    echo $INITIAL | grep -o '"ACADEMIC": {[^}]*}' | head -1
fi

# 2. Check certificate eligibility
echo -e "\n${YELLOW}[2] Certificate Eligibility Check${NC}"
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
    echo -e "${GREEN}✓ Student is eligible for certificate!${NC}"
else
    echo -e "${RED}✗ Student is NOT eligible${NC}"
fi

# 3. If eligible, issue certificate
if [ "$IS_ELIGIBLE" == "true" ]; then
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
    
    if echo $CERT | grep -q "certificate_id"; then
        echo -e "${GREEN}✅ Certificate issued successfully!🎓${NC}"
        VERIFY_CODE=$(echo $CERT | grep -o '"verification_code":"[^"]*"' | cut -d'"' -f4)
        echo -e "${BLUE}Verification Code: ${VERIFY_CODE}${NC}"
    else
        echo -e "${RED}❌ Failed to issue certificate${NC}"
    fi
fi

echo -e "\n${GREEN}========================================="
echo "Test Complete!"
echo "=========================================${NC}"
