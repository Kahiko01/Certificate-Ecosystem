#!/bin/bash

echo "========================================="
echo "🚀 Starting All Certificate Services"
echo "========================================="

cd ~/university-certificate-ecosystem/09_system_architecture

# Function to start a service
start_service() {
    local name=$1
    local port=$2
    local file=$3
    local deps=$4
    
    echo "Starting $name on port $port..."
    
    sudo docker stop $name 2>/dev/null
    sudo docker rm $name 2>/dev/null
    
    sudo docker run -d \
      --name $name \
      --network certificate-network \
      -p $port:$port \
      -v $(pwd)/$file:/app/$file \
      -w /app \
      python:3.11-slim \
      sh -c "pip install -q fastapi uvicorn psycopg2-binary pyjwt && python $file"
    
    sleep 3
}

# Start PostgreSQL if not running
if ! sudo docker ps | grep -q certificate-postgres; then
    echo "Starting PostgreSQL..."
    sudo docker run -d \
      --name certificate-postgres \
      --network certificate-network \
      -e POSTGRES_DB=certificate_ecosystem \
      -e POSTGRES_USER=cert_admin \
      -e POSTGRES_PASSWORD=secure_password_123 \
      postgres:15-alpine
fi

# Start Redis if not running
if ! sudo docker ps | grep -q certificate-redis; then
    echo "Starting Redis..."
    sudo docker run -d \
      --name certificate-redis \
      --network certificate-network \
      redis:7-alpine
fi

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
sleep 10

# Initialize database if needed
sudo docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem -c "SELECT 1" 2>/dev/null || {
    echo "Initializing database..."
    sudo docker cp init_db.sql certificate-postgres:/tmp/ 2>/dev/null
    sudo docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem -f /tmp/init_db.sql 2>/dev/null
}

# Start services
start_service "certificate-service" "8000" "certificate_service_clearance.py"
start_service "auth-service" "8001" "auth_service_with_tracking.py"
start_service "telemetry-service" "8002" "telemetry_service.py"

# Wait for all services
echo "Waiting for services to start..."
sleep 10

# Check all services
echo -e "\n========================================="
echo "✅ Service Status"
echo "========================================="
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n========================================="
echo "Testing Endpoints"
echo "========================================="

# Test certificate service
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Certificate Service: http://localhost:8000"
else
    echo "❌ Certificate Service: Failed"
fi

# Test auth service
if curl -s http://localhost:8001/ > /dev/null 2>&1; then
    echo "✅ Auth Service: http://localhost:8001"
else
    echo "❌ Auth Service: Failed"
fi

# Test telemetry service
if curl -s http://localhost:8002/ > /dev/null 2>&1; then
    echo "✅ Telemetry Service: http://localhost:8002"
else
    echo "❌ Telemetry Service: Failed"
fi

echo -e "\n🌐 Open Dashboard: http://localhost:9001/master_dashboard.html"
