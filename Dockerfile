# ============================================
# CERTIFICATE ECOSYSTEM - Dockerfile
# Complete Certificate & Record Management System
# ============================================

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY 09_system_architecture/ ./09_system_architecture/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Expose ports
EXPOSE 8000 8001 8002

# Start the application
CMD ["sh", "-c", "cd 09_system_architecture && python3 auth_service.py & python3 -m http.server 9001 --bind 0.0.0.0"]
