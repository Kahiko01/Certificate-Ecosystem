#!/bin/bash

# ============================================
# CERTIFICATE ECOSYSTEM - Installation Script
# Complete Certificate & Record Management System
# ============================================

echo "========================================="
echo "🚀 Certificate Ecosystem - Installation"
echo "========================================="

# Check Python version
echo ""
echo "📋 Checking Python version..."
python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
echo "✅ Python $python_version"

# Check if pip is installed
echo ""
echo "📦 Checking pip..."
if command -v pip3 &> /dev/null; then
    echo "✅ pip is installed"
else
    echo "❌ pip not found. Installing..."
    sudo apt update && sudo apt install python3-pip -y
fi

# Create virtual environment
echo ""
echo "📦 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Check if Docker is installed
echo ""
echo "🐳 Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
else
    echo "⚠️ Docker not found. Installing..."
    sudo apt update
    sudo apt install docker.io docker-compose -y
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Create directories
echo ""
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p certificates
mkdir -p uploads
mkdir -p data
mkdir -p backups

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
DASHBOARD_PORT=9001

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Environment
ENVIRONMENT=development
DEBUG=True
ENV
    echo "✅ .env file created"
else
    echo "⚠️ .env file already exists"
fi

# Initialize database
echo ""
echo "🗄️ Initializing database..."
if command -v docker &> /dev/null && docker ps &> /dev/null; then
    echo "Using Docker for database..."
    docker-compose up -d postgres redis
    sleep 10
    docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem < 08_database_design/simple_schema.sql
    docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem < 08_database_design/clearance_schema.sql
    docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem < 08_database_design/rbac_schema.sql
    echo "✅ Database initialized"
else
    echo "⚠️ Docker not available. Please set up PostgreSQL manually."
fi

# Set up pre-commit hooks
echo ""
echo "🔧 Setting up pre-commit hooks..."
if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo "✅ Pre-commit hooks installed"
fi

# Create startup script
echo ""
echo "📝 Creating startup script..."
cat > start.sh << 'START'
#!/bin/bash

echo "========================================="
echo "🚀 Starting Certificate Ecosystem"
echo "========================================="

cd 09_system_architecture

# Start Auth Service
echo "🔐 Starting Auth Service..."
python3 auth_service.py > ../logs/auth.log 2>&1 &

# Start Dashboard
echo "📊 Starting Dashboard Server..."
python3 -m http.server 9001 --bind 0.0.0.0 > ../logs/dashboard.log 2>&1 &

sleep 5

# Get IP
WIN_IP=$(ip route show default | awk '{print $3}' 2>/dev/null || echo "localhost")

echo ""
echo "========================================="
echo "✅ Services Started!"
echo "========================================="
echo ""
echo "🌐 Access URLs:"
echo "   Local: http://localhost:9001"
echo "   Network: http://$WIN_IP:9001"
echo ""
echo "🔑 Login Credentials:"
echo "   Admin: system_admin / admin_hash"
echo "   Registrar: registrar / default_hash"
echo "   Dean: dean / default_hash"
echo "   Student: student1 / default_hash"
echo ""
echo "📋 Logs:"
echo "   Auth: tail -f logs/auth.log"
echo "   Dashboard: tail -f logs/dashboard.log"
echo "========================================="
START

chmod +x start.sh
echo "✅ Startup script created"

echo ""
echo "========================================="
echo "✅ Installation Complete!"
echo "========================================="
echo ""
echo "📋 Next steps:"
echo "   1. source venv/bin/activate"
echo "   2. ./start.sh"
echo "   3. Open http://localhost:9001"
echo ""
echo "📚 Documentation:"
echo "   README.md - Project overview"
echo "   PROJECT_REQUIREMENTS.md - Requirements"
echo "   API_DOCUMENTATION.md - API docs"
echo ""
echo "🔧 Database Commands:"
echo "   docker-compose up -d postgres redis"
echo "   docker-compose down"
echo ""
echo "========================================="
