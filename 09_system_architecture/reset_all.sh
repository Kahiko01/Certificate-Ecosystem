#!/bin/bash

echo "Resetting Certificate Ecosystem..."

# Stop all containers
sudo docker stop certificate-service certificate-postgres certificate-redis 2>/dev/null
sudo docker rm certificate-service certificate-postgres certificate-redis 2>/dev/null

# Create network
sudo docker network create certificate-network 2>/dev/null || true

# Start PostgreSQL
sudo docker run -d --name certificate-postgres --network certificate-network \
  -e POSTGRES_DB=certificate_ecosystem \
  -e POSTGRES_USER=cert_admin \
  -e POSTGRES_PASSWORD=secure_password_123 \
  postgres:15-alpine

# Start Redis
sudo docker run -d --name certificate-redis --network certificate-network redis:7-alpine

# Wait for PostgreSQL
sleep 15

# Initialize database
sudo docker exec -i certificate-postgres psql -U cert_admin -d certificate_ecosystem << 'SQL'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
    student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    admission_date DATE NOT NULL,
    current_status VARCHAR(20) CHECK (current_status IN ('ACTIVE', 'GRADUATED', 'WITHDRAWN')),
    mode_of_study VARCHAR(20) CHECK (mode_of_study IN ('FULL_TIME', 'PART_TIME')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS programmes (
    programme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    level VARCHAR(50) CHECK (level IN ('CERTIFICATE', 'DIPLOMA', 'BACHELORS', 'MASTERS', 'PHD')),
    duration_years INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS certificates (
    certificate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_number VARCHAR(50) UNIQUE NOT NULL,
    verification_code VARCHAR(20) UNIQUE NOT NULL,
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    programme_id UUID REFERENCES programmes(programme_id),
    issue_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('GENERATED', 'ISSUED', 'COLLECTED', 'REVOKED')),
    file_hash VARCHAR(64),
    collection_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_certificates_verification_code ON certificates(verification_code);
CREATE INDEX IF NOT EXISTS idx_certificates_student_id ON certificates(student_id);

INSERT INTO programmes (programme_id, code, name, level, duration_years) 
VALUES ('6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74', 'BSCS', 'Bachelor of Science in Computer Science', 'BACHELORS', 4)
ON CONFLICT (code) DO NOTHING;

INSERT INTO users (user_id, username, email, password_hash, first_name, last_name)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'john_doe', 'john.doe@university.ac.ke', 'hashed_password', 'John', 'Doe')
ON CONFLICT (username) DO NOTHING;

INSERT INTO students (student_id, user_id, student_number, admission_date, current_status, mode_of_study)
VALUES ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 'S2024001', '2024-09-01', 'ACTIVE', 'FULL_TIME')
ON CONFLICT (student_number) DO NOTHING;

CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.verification_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_verification_code ON certificates;
CREATE TRIGGER set_verification_code BEFORE INSERT ON certificates
    FOR EACH ROW WHEN (NEW.verification_code IS NULL)
    EXECUTE FUNCTION generate_verification_code();
SQL

# Start certificate service
sudo docker run -d \
  --name certificate-service \
  --network certificate-network \
  -p 8000:8000 \
  -v $(pwd)/simple_service.py:/app/simple_service.py \
  -w /app \
  python:3.11-slim \
  sh -c "pip install -q fastapi uvicorn psycopg2-binary && python simple_service.py"

sleep 10

echo "Checking API..."
curl http://localhost:8000/health
