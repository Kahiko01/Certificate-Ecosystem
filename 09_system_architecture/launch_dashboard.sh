#!/bin/bash

echo "========================================="
echo "🎓 Certificate Ecosystem Dashboard"
echo "========================================="

# Find an available port
PORT=3000
while lsof -i :$PORT > /dev/null 2>&1; do
    PORT=$((PORT + 1))
done

echo "Starting dashboard on port $PORT"
echo "Open in browser: http://localhost:$PORT/dashboard_final.html"

# Start the server
python3 -m http.server $PORT &

echo ""
echo "Press Ctrl+C to stop the server"
wait
