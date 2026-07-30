#!/bin/bash

echo "========================================="
echo "🔄 Updating Port Forwarding"
echo "========================================="

WSL_IP=$(hostname -I | awk '{print $1}')
WIN_IP=$(ip route show default | awk '{print $3}')

echo ""
echo "📡 Current IPs:"
echo "   WSL IP: $WSL_IP"
echo "   Windows IP: $WIN_IP"
echo ""

echo "📋 Copy these commands and run in Windows PowerShell (As Administrator):"
echo ""
echo "========================================="
echo "# Remove old forwarding"
echo "netsh interface portproxy delete v4tov4 listenport=9001"
echo "netsh interface portproxy delete v4tov4 listenport=8000"
echo "netsh interface portproxy delete v4tov4 listenport=8001"
echo "netsh interface portproxy delete v4tov4 listenport=8002"
echo ""
echo "# Add new forwarding with WSL IP: $WSL_IP"
echo "netsh interface portproxy add v4tov4 listenport=9001 listenaddress=0.0.0.0 connectport=9001 connectaddress=$WSL_IP"
echo "netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=$WSL_IP"
echo "netsh interface portproxy add v4tov4 listenport=8001 listenaddress=0.0.0.0 connectport=8001 connectaddress=$WSL_IP"
echo "netsh interface portproxy add v4tov4 listenport=8002 listenaddress=0.0.0.0 connectport=8002 connectaddress=$WSL_IP"
echo ""
echo "# Verify"
echo "netsh interface portproxy show all"
echo "========================================="
echo ""
echo "📱 Your phone URL: http://$WIN_IP:9001"
echo "========================================="
