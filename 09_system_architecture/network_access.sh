#!/bin/bash

echo "========================================="
echo "🌐 CERTIFICATE ECOSYSTEM - NETWORK ACCESS"
echo "========================================="

# Get IP address
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "📡 Your Local IP: $IP"
echo ""

# Check services
echo "🔍 Checking Services:"

# Dashboard
if curl -s http://localhost:9001/ > /dev/null 2>&1; then
    echo "   ✅ Dashboard: http://$IP:9001"
else
    echo "   ❌ Dashboard not running"
fi

# Auth Service
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "   ✅ Auth Service: http://$IP:8001"
else
    echo "   ❌ Auth Service not running"
fi

# Certificate Service
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Certificate Service: http://$IP:8000"
else
    echo "   ❌ Certificate Service not running"
fi

echo ""
echo "========================================="
echo "🌐 ACCESS FROM OTHER DEVICES:"
echo ""
echo "   Main URL: http://$IP:9001"
echo "   Login: http://$IP:9001/login_with_rbac.html"
echo "   Dashboard: http://$IP:9001/dashboard_hub.html"
echo ""
echo "🔑 Test Credentials:"
echo "   Admin: system_admin / admin_hash"
echo "   Registrar: registrar / default_hash"
echo "   Dean: dean / default_hash"
echo ""
echo "⚠️  Note: Make sure firewall allows connections"
echo "========================================="

# Try to open in browser
if command -v xdg-open &> /dev/null; then
    xdg-open "http://$IP:9001" 2>/dev/null
fi
