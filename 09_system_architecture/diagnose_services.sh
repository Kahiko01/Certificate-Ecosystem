#!/bin/bash

echo "========================================="
echo "🔍 Service Diagnostics"
echo "========================================="

echo -e "\n1. Container Status:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n2. Service Logs:"
for service in auth-service pdf-service email-service; do
    echo -e "\n--- $service ---"
    sudo docker logs $service --tail 5 2>&1
done

echo -e "\n3. Port Listening:"
sudo netstat -tulpn | grep -E "8001|8003|8004" || echo "No services listening on ports 8001, 8003, 8004"

echo -e "\n4. Test Endpoints:"
for port in 8001 8003 8004; do
    echo -n "Port $port: "
    curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health
    echo ""
done
