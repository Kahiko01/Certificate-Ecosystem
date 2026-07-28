-- =============================================
-- SIMPLE START - UNIVERSITY CERTIFICATE ECOSYSTEM
-- Essential Tables to Get Started
-- =============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS
CREATE TABLE users (
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

-- 2. STUDENTS
CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    admission_date DATE NOT NULL,
    current_status VARCHAR(20) CHECK (current_status IN ('ACTIVE', 'GRADUATED', 'WITHDRAWN')),
    mode_of_study VARCHAR(20) CHECK (mode_of_study IN ('FULL_TIME', 'PART_TIME')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. FACULTIES
CREATE TABLE faculties (
    faculty_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. DEPARTMENTS
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    faculty_id UUID NOT NULL REFERENCES faculties(faculty_id) ON DELETE CASCADE,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. PROGRAMMES
CREATE TABLE programmes (
    programme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    level VARCHAR(50) CHECK (level IN ('CERTIFICATE', 'DIPLOMA', 'BACHELORS', 'MASTERS', 'PHD')),
    duration_years INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. COURSES
CREATE TABLE courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    credit_units INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. STUDENT_PROGRAMMES
CREATE TABLE student_programmes (
    student_programme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    programme_id UUID NOT NULL REFERENCES programmes(programme_id) ON DELETE CASCADE,
    registration_date DATE NOT NULL,
    expected_completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('REGISTERED', 'ACTIVE', 'COMPLETED', 'WITHDRAWN')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, programme_id)
);

-- 8. COURSE_REGISTRATIONS
CREATE TABLE course_registrations (
    registration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_programme_id UUID NOT NULL REFERENCES student_programmes(student_programme_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    academic_year INTEGER NOT NULL,
    semester INTEGER CHECK (semester IN (1, 2)),
    status VARCHAR(20) CHECK (status IN ('REGISTERED', 'COMPLETED', 'FAILED', 'WITHDRAWN')),
    final_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_programme_id, course_id, academic_year, semester)
);

-- 9. CERTIFICATES
CREATE TABLE certificates (
    certificate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_number VARCHAR(50) UNIQUE NOT NULL,
    verification_code VARCHAR(20) UNIQUE NOT NULL,
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    programme_id UUID NOT NULL REFERENCES programmes(programme_id),
    issue_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('GENERATED', 'ISSUED', 'COLLECTED', 'REVOKED')),
    file_hash VARCHAR(64),
    collection_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. VERIFICATION_LOGS
CREATE TABLE verification_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    verification_code VARCHAR(20) NOT NULL,
    verifier_ip INET,
    verification_result BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. ROLES
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. USER_ROLES
CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_students_student_number ON students(student_number);
CREATE INDEX idx_certificates_verification_code ON certificates(verification_code);
CREATE INDEX idx_certificates_student_id ON certificates(student_id);
CREATE INDEX idx_verification_logs_certificate_id ON verification_logs(certificate_id);

-- Insert sample roles
INSERT INTO roles (role_id, name, description) VALUES
    (uuid_generate_v4(), 'SUPER_ADMIN', 'System Administrator'),
    (uuid_generate_v4(), 'REGISTRAR', 'Registrar Office'),
    (uuid_generate_v4(), 'STUDENT', 'Student User'),
    (uuid_generate_v4(), 'DEAN', 'Faculty Dean');

-- Insert sample faculty
INSERT INTO faculties (faculty_id, code, name) VALUES
    (uuid_generate_v4(), 'FICT', 'Faculty of Information and Communication Technology'),
    (uuid_generate_v4(), 'FBE', 'Faculty of Business and Economics');

-- Insert sample departments
INSERT INTO departments (department_id, faculty_id, code, name) VALUES
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FICT'), 'CS', 'Department of Computer Science'),
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FICT'), 'IS', 'Department of Information Systems');

-- Insert sample programmes
INSERT INTO programmes (programme_id, department_id, code, name, level, duration_years) VALUES
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'BSCS', 'Bachelor of Science in Computer Science', 'BACHELORS', 4),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'IS'), 'BBIT', 'Bachelor of Business Information Technology', 'BACHELORS', 4);

-- Insert sample user
INSERT INTO users (user_id, username, email, password_hash, first_name, last_name) VALUES
    (uuid_generate_v4(), 'admin', 'admin@university.ac.ke', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewd5dLzZvJWQrP3G', 'System', 'Admin');

-- Create a view for certificate verification
CREATE VIEW vw_certificate_verification AS
SELECT 
    c.certificate_number,
    c.verification_code,
    c.issue_date,
    c.status,
    u.first_name,
    u.last_name,
    s.student_number,
    p.name as programme_name
FROM certificates c
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
JOIN programmes p ON c.programme_id = p.programme_id;

-- Function to generate verification code
CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.verification_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-generate verification code
CREATE TRIGGER set_verification_code BEFORE INSERT ON certificates
    FOR EACH ROW
    WHEN (NEW.verification_code IS NULL)
    EXECUTE FUNCTION generate_verification_code();

-- Function to generate certificate number
CREATE OR REPLACE FUNCTION generate_certificate_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.certificate_number := 'CERT-' || TO_CHAR(NEW.issue_date, 'YYYY') || '-' || 
                             LPAD(CAST(NEXTVAL('certificate_number_seq') AS TEXT), 6, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create sequence for certificate numbers
CREATE SEQUENCE IF NOT EXISTS certificate_number_seq START 1;

-- Trigger to auto-generate certificate number
CREATE TRIGGER set_certificate_number BEFORE INSERT ON certificates
    FOR EACH ROW
    WHEN (NEW.certificate_number IS NULL)
    EXECUTE FUNCTION generate_certificate_number();

-- Display success message
SELECT 'Database setup completed successfully!' as status;
