#!/bin/bash

echo "Creating department accounts..."

# Define department users
declare -A users=(
    ["finance_officer"]="Finance Officer"
    ["academic_officer"]="Academic Officer"
    ["library_officer"]="Library Officer"
    ["accommodation_officer"]="Accommodation Officer"
    ["discipline_officer"]="Discipline Officer"
    ["registry_officer"]="Registry Officer"
    ["senate_officer"]="Senate Officer"
)

for username in "${!users[@]}"; do
    fullname="${users[$username]}"
    first_name=$(echo $fullname | cut -d' ' -f1)
    last_name=$(echo $fullname | cut -d' ' -f2)
    
    echo "Creating user: $username ($fullname)"
    
    curl -s -X POST http://localhost:8001/auth/register \
      -H "Content-Type: application/json" \
      -d "{
        \"username\": \"$username\",
        \"email\": \"$username@university.ac.ke\",
        \"password\": \"default_hash\",
        \"first_name\": \"$first_name\",
        \"last_name\": \"$last_name\",
        \"role\": \"${username^^}_OFFICER\"
      }" | python3 -m json.tool
done

echo -e "\n✅ All department accounts created!"
