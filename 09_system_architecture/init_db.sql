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
VALUES 
    ('6d3db2b3-0a11-49c9-a5c9-8d5b7782cf74', 'BSCS', 'Bachelor of Science in Computer Science', 'BACHELORS', 4)
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.verification_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_verification_code ON certificates;
CREATE TRIGGER set_verification_code BEFORE INSERT ON certificates
    FOR EACH ROW
    WHEN (NEW.verification_code IS NULL)
    EXECUTE FUNCTION generate_verification_code();

CREATE OR REPLACE FUNCTION generate_certificate_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.certificate_number := 'CERT-' || TO_CHAR(NEW.issue_date, 'YYYY') || '-' || 
                             LPAD(CAST(FLOOR(RANDOM() * 999999) AS TEXT), 6, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_certificate_number ON certificates;
CREATE TRIGGER set_certificate_number BEFORE INSERT ON certificates
    FOR EACH ROW
    WHEN (NEW.certificate_number IS NULL)
    EXECUTE FUNCTION generate_certificate_number();
