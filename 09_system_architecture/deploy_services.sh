#!/bin/bash

echo "========================================="
echo "🚀 Deploying All Services"
echo "========================================="

# Stop existing services
echo "Stopping existing services..."
sudo docker stop pdf-service email-service 2>/dev/null
sudo docker rm pdf-service email-service 2>/dev/null

# Build and start PDF service
echo "Starting PDF Service..."
sudo docker build -f Dockerfile.pdf -t pdf-service .
sudo docker run -d \
  --name pdf-service \
  --network certificate-network \
  -p 8003:8003 \
  -v $(pwd)/certificates:/app/certificates \
  pdf-service

# Build and start Email service
echo "Starting Email Service..."
sudo docker build -f Dockerfile.email -t email-service .
sudo docker run -d \
  --name email-service \
  --network certificate-network \
  -p 8004:8004 \
  --env-file .env \
  email-service

# Wait for services
sleep 5

echo "✅ Services deployed!"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
