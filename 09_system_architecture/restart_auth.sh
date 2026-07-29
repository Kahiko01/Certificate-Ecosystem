#!/bin/bash

echo "========================================="
echo "🔄 Restarting Auth Service"
echo "========================================="

# Kill existing processes
pkill -f ultimate_service 2>/dev/null
sudo systemctl stop ultimate-auth 2>/dev/null

cd /home/Cybergoat/university-certificate-ecosystem/09_system_architecture

# Start with nohup
nohup python3 ultimate_service.py > ultimate_service.log 2>&1 &
disown

sleep 3

# Test
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Auth Service is running"
    echo "🌐 Login: http://localhost:9001/login_with_rbac.html"
else
    echo "❌ Auth Service failed to start"
    echo "📋 Check logs: tail -20 ultimate_service.log"
fi
