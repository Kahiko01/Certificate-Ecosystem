#!/bin/bash

echo "========================================="
echo "🌐 Starting Network Server"
echo "========================================="

cd ~/university-certificate-ecosystem/09_system_architecture

# Kill existing servers
pkill -f "http.server"

# Start on all interfaces
echo "📊 Starting dashboard on 0.0.0.0:9001"
python3 -m http.server 9001 --bind 0.0.0.0 &

sleep 2

# Get IP
IP=$(ip route show default | awk '{print $3}')
echo ""
echo "✅ Server running on:"
echo "   http://localhost:9001"
echo "   http://$IP:9001"
echo ""
echo "📱 Your phone should use: http://$IP:9001"
echo "========================================="
