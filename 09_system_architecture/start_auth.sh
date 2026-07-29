#!/bin/bash
echo "🚀 Starting Auth Service..."
cd ~/university-certificate-ecosystem/09_system_architecture
python3 auth_service.py &
echo "✅ Auth Service running on http://localhost:8001"
