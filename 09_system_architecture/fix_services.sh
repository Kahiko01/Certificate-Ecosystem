#!/bin/bash

echo "========================================="
echo "🔧 Fixing Services"
echo "========================================="

cd /home/Cybergoat/university-certificate-ecosystem/09_system_architecture

# Stop all services
echo "Stopping services..."
sudo docker stop certificate-service auth-service 2>/dev/null
sudo docker rm certificate-service auth-service 2>/dev/null

# Start certificate service
echo "Starting certificate service on port 8000..."
sudo docker run -d \
  --name certificate-service \
  --network certificate-network \
  -p 8000:8000 \
  -v $(pwd)/simple_service.py:/app/simple_service.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python -u simple_service.py"

# Start auth service
echo "Starting auth service on port 8001..."
sudo docker run -d \
  --name auth-service \
  --network certificate-network \
  -p 8001:8001 \
  -v $(pwd)/simple_service_with_auth.py:/app/simple_service_with_auth.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn && python -u simple_service_with_auth.py"

# Wait for services to start
echo "Waiting for services to start..."
sleep 15

# Test services
echo -e "\n🔍 Testing Services:"
echo -n "Certificate Service (8000): "
curl -s http://localhost:8000/health > /dev/null && echo "✅ Online" || echo "❌ Offline"

echo -n "Auth Service (8001): "
curl -s http://localhost:8001/health > /dev/null && echo "✅ Online" || echo "❌ Offline"

echo -e "\n📋 Running Containers:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
