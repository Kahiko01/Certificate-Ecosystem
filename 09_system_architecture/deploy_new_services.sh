#!/bin/bash

echo "========================================="
echo "🚀 Deploying PDF & Email Services"
echo "========================================="

cd ~/university-certificate-ecosystem/09_system_architecture

# Stop existing services
echo "Stopping existing services..."
sudo docker stop pdf-service email-service 2>/dev/null
sudo docker rm pdf-service email-service 2>/dev/null

# Deploy PDF Service
echo "Starting PDF Service on port 8003..."
sudo docker run -d \
  --name pdf-service \
  --network certificate-network \
  -p 8003:8003 \
  -v $(pwd):/app \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python certificate_pdf.py"

# Deploy Email Service
echo "Starting Email Service on port 8004..."
sudo docker run -d \
  --name email-service \
  --network certificate-network \
  -p 8004:8004 \
  -v $(pwd):/app \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python email_service.py"

# Wait for services
sleep 10

echo -e "\n✅ Services Deployed!"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test services
echo -e "\nTesting services..."
curl -s http://localhost:8003/health > /dev/null && echo "✅ PDF Service: Online" || echo "❌ PDF Service: Offline"
curl -s http://localhost:8004/health > /dev/null && echo "✅ Email Service: Online" || echo "❌ Email Service: Offline"
