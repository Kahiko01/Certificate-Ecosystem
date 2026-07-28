#!/bin/bash

echo "Fixing services..."

# Stop all
sudo docker stop auth-service telemetry-service certificate-service 2>/dev/null
sudo docker rm auth-service telemetry-service certificate-service 2>/dev/null

# Start certificate service
sudo docker run -d \
  --name certificate-service \
  --network certificate-network \
  -p 8000:8000 \
  -v $(pwd)/simple_service.py:/app/simple_service.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python simple_service.py"

# Start auth service
sudo docker run -d \
  --name auth-service \
  --network certificate-network \
  -p 8001:8001 \
  -v $(pwd)/auth_service_simple.py:/app/auth_service.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary pyjwt && python auth_service.py"

# Start telemetry service
sudo docker run -d \
  --name telemetry-service \
  --network certificate-network \
  -p 8002:8002 \
  -v $(pwd)/telemetry_service.py:/app/telemetry_service.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python telemetry_service.py"

sleep 10

echo "Services restarted!"
sudo docker ps --format "table {{.Names}}\t{{.Status}}"
