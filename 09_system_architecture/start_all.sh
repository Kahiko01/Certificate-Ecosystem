#!/bin/bash

echo "========================================="
echo "🎓 Starting Certificate Ecosystem"
echo "========================================="

# Check if API is running
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "⚠️  API is not running! Starting services..."
    cd ~/university-certificate-ecosystem/09_system_architecture
    sudo docker start certificate-service 2>/dev/null || {
        echo "Starting containers..."
        sudo docker run -d --name certificate-service --network certificate-network -p 8000:8000 \
          -v $(pwd)/simple_service.py:/app/simple_service.py -w /app \
          python:3.11-slim sh -c "pip install -q fastapi uvicorn psycopg2-binary && python simple_service.py"
    }
    sleep 5
fi

echo "✅ API running at http://localhost:8000"

# Find free port for dashboard
PORT=9000
while lsof -i :$PORT > /dev/null 2>&1; do
    PORT=$((PORT + 1))
done

echo "📊 Starting dashboard on port $PORT"
echo "🌐 Open in browser: http://localhost:$PORT/dashboard_working.html"

# Start the server
python3 -m http.server $PORT &

echo ""
echo "Press Ctrl+C to stop the dashboard server"
wait
