#!/bin/bash

echo "========================================="
echo "🚀 Certificate Ecosystem - Setup"
echo "========================================="

# Check Python version
echo "📋 Checking Python version..."
python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
echo "✅ Python $python_version"

# Create virtual environment
echo ""
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p certificates
mkdir -p uploads
mkdir -p data

# Create .env file
echo ""
echo "📝 Creating .env file..."
if [ ! -f .env ]; then
    cat > .env << 'ENV'
# Database Configuration
POSTGRES_DB=certificate_ecosystem
POSTGRES_USER=cert_admin
POSTGRES_PASSWORD=secure_password_123
DATABASE_URL=postgresql://cert_admin:secure_password_123@localhost:5432/certificate_ecosystem

# Redis Configuration
REDIS_URL=redis://localhost:6379

# JWT Configuration
SECRET_KEY=your-super-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Service Ports
CERTIFICATE_SERVICE_PORT=8000
AUTH_SERVICE_PORT=8001
TELEMETRY_SERVICE_PORT=8002
PDF_SERVICE_PORT=8003
EMAIL_SERVICE_PORT=8004
GENERATOR_SERVICE_PORT=8005

# Dashboard Server
DASHBOARD_PORT=9001

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
ENV
    echo "✅ .env file created"
else
    echo "⚠️ .env file already exists"
fi

# Set up pre-commit hooks
echo ""
echo "🔧 Setting up pre-commit hooks..."
pre-commit install

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "🌐 Next steps:"
echo "   1. source venv/bin/activate"
echo "   2. python3 auth_service.py &"
echo "   3. python3 -m http.server 9001 &"
echo "   4. Open http://localhost:9001"
echo ""
echo "📚 For more information, see README.md"
echo "========================================="
