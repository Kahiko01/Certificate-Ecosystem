-- =============================================
-- UNIVERSITY CERTIFICATE ECOSYSTEM
-- Complete Database Schema
-- PostgreSQL 15+
-- =============================================

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- CORE SYSTEM TABLES
-- =============================================

-- 1. USERS TABLE (Authentication & Core Identity)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    national_id VARCHAR(20),
    passport_number VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('M', 'F', 'OTHER')),
    phone_number VARCHAR(20),
    alternate_phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    is_locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id)
);

-- 2. STUDENTS TABLE (Extended student information)
CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    admission_date DATE NOT NULL,
    expected_graduation_date DATE,
    current_status VARCHAR(20) CHECK (current_status IN ('ACTIVE', 'SUSPENDED', 'PROBATION', 'GRADUATED', 'WITHDRAWN', 'DEFERRED')),
    entry_qualification TEXT,
    mode_of_study VARCHAR(20) CHECK (mode_of_study IN ('FULL_TIME', 'PART_TIME', 'DISTANCE', 'EVENING', 'ONLINE')),
    is_international BOOLEAN DEFAULT FALSE,
    nationality VARCHAR(100),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    profile_image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. EMPLOYEES TABLE (Staff, Faculty, Administration)
CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    department_id UUID, -- Foreign key to departments
    employment_type VARCHAR(20) CHECK (employment_type IN ('PERMANENT', 'CONTRACT', 'VISITING', 'PART_TIME')),
    date_joined DATE NOT NULL,
    date_left DATE,
    office_location VARCHAR(100),
    extension_number VARCHAR(20),
    is_teaching_staff BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ACADEMIC STRUCTURE TABLES
-- =============================================

-- 4. FACULTIES
CREATE TABLE faculties (
    faculty_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    dean_id UUID REFERENCES employees(employee_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. DEPARTMENTS
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    faculty_id UUID NOT NULL REFERENCES faculties(faculty_id) ON DELETE CASCADE,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    hod_id UUID REFERENCES employees(employee_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. PROGRAMMES (Degree Programs)
CREATE TABLE programmes (
    programme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    level VARCHAR(50) CHECK (level IN ('CERTIFICATE', 'DIPLOMA', 'HIGHER_DIPLOMA', 'BACHELORS', 'MASTERS', 'PHD', 'POSTGRADUATE_DIPLOMA', 'PROFESSIONAL')),
    duration_years INTEGER NOT NULL,
    duration_months INTEGER DEFAULT 0,
    description TEXT,
    credit_units_required INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. COURSES (Individual Subjects)
CREATE TABLE courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    credit_units INTEGER NOT NULL,
    course_type VARCHAR(20) CHECK (course_type IN ('CORE', 'ELECTIVE', 'UNIVERSITY_WIDE')),
    semester_offered INTEGER CHECK (semester_offered IN (1, 2, 3)),
    year_offered INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. STUDENT_PROGRAMMES (Enrollment)
CREATE TABLE student_programmes (
    student_programme_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    programme_id UUID NOT NULL REFERENCES programmes(programme_id) ON DELETE CASCADE,
    registration_date DATE NOT NULL,
    expected_completion_date DATE,
    actual_completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('REGISTERED', 'ACTIVE', 'COMPLETED', 'WITHDRAWN', 'DEFERRED')),
    academic_year INTEGER NOT NULL,
    intake VARCHAR(20) CHECK (intake IN ('SEPTEMBER', 'JANUARY', 'MAY')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, programme_id)
);

-- 9. COURSE_REGISTRATIONS
CREATE TABLE course_registrations (
    registration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_programme_id UUID NOT NULL REFERENCES student_programmes(student_programme_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    academic_year INTEGER NOT NULL,
    semester INTEGER CHECK (semester IN (1, 2, 3)),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    withdrawal_date DATE,
    status VARCHAR(20) CHECK (status IN ('REGISTERED', 'WITHDRAWN', 'COMPLETED', 'FAILED', 'INCOMPLETE')),
    final_grade VARCHAR(5),
    final_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_programme_id, course_id, academic_year, semester)
);

-- =============================================
-- ASSESSMENTS & EXAMINATIONS
-- =============================================

-- 10. ASSESSMENTS (Continuous Assessment Tests, Assignments, etc.)
CREATE TABLE assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL REFERENCES course_registrations(registration_id) ON DELETE CASCADE,
    assessment_type VARCHAR(30) CHECK (assessment_type IN ('CAT1', 'CAT2', 'ASSIGNMENT', 'PRACTICAL', 'PROJECT', 'PRESENTATION')),
    score DECIMAL(5,2),
    weight_percentage DECIMAL(5,2) NOT NULL,
    date_taken DATE,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. EXAMINATIONS (Final Exams)
CREATE TABLE examinations (
    examination_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL REFERENCES course_registrations(registration_id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,
    exam_time TIME,
    venue VARCHAR(100),
    score DECIMAL(5,2),
    weight_percentage DECIMAL(5,2) NOT NULL,
    supervisor_id UUID REFERENCES employees(employee_id),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- CERTIFICATE SYSTEM
-- =============================================

-- 12. CERTIFICATE_TEMPLATES (Design templates for different document types)
CREATE TABLE certificate_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('DEGREE', 'DIPLOMA', 'CERTIFICATE', 'TRANSCRIPT', 'PROVISIONAL', 'LETTER', 'BADGE', 'MICRO_CREDENTIAL', 'HONORARY', 'PROFESSIONAL', 'ATTACHMENT', 'INTERNSHIP')),
    template_html TEXT NOT NULL, -- HTML/XML template
    template_css TEXT,
    template_pdf_settings JSONB, -- PDF generation settings
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id)
);

-- 13. GRADUATION_LISTS (Senate-approved lists)
CREATE TABLE graduation_lists (
    graduation_list_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    academic_year INTEGER NOT NULL,
    graduation_date DATE NOT NULL,
    ceremony_number VARCHAR(20),
    status VARCHAR(20) CHECK (status IN ('DRAFT', 'DEPARTMENT_APPROVED', 'SENATE_APPROVED', 'PUBLISHED')),
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. GRADUATION_LIST_STUDENTS (Link students to graduation lists)
CREATE TABLE graduation_list_students (
    graduation_list_student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    graduation_list_id UUID NOT NULL REFERENCES graduation_lists(graduation_list_id) ON DELETE CASCADE,
    student_programme_id UUID NOT NULL REFERENCES student_programmes(student_programme_id) ON DELETE CASCADE,
    clearance_status VARCHAR(20) CHECK (clearance_status IN ('PENDING', 'CLEARED', 'NOT_CLEARED')),
    final_cgpa DECIMAL(4,2),
    honors_class VARCHAR(50) CHECK (honors_class IN ('FIRST_CLASS', 'SECOND_CLASS_UPPER', 'SECOND_CLASS_LOWER', 'PASS', 'NO_HONORS', 'DISTINCTION', 'MERIT')),
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(graduation_list_id, student_programme_id)
);

-- 15. CERTIFICATES
CREATE TABLE certificates (
    certificate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_number VARCHAR(50) UNIQUE NOT NULL,
    verification_code VARCHAR(20) UNIQUE NOT NULL, -- Short code for QR verification
    template_id UUID NOT NULL REFERENCES certificate_templates(template_id),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    graduation_list_student_id UUID NOT NULL REFERENCES graduation_list_students(graduation_list_student_id),
    issue_date DATE NOT NULL,
    expiry_date DATE, -- For certifications that expire (e.g., professional)
    status VARCHAR(20) CHECK (status IN ('GENERATED', 'SIGNED', 'ISSUED', 'COLLECTED', 'REVOKED', 'REPLACED', 'ARCHIVED')),
    file_path TEXT, -- Path to stored PDF
    file_hash VARCHAR(64), -- SHA-256 hash for tamper detection
    document_metadata JSONB, -- Flexible metadata storage
    qr_code_image TEXT, -- Path to QR code image
    collection_date DATE,
    collection_method VARCHAR(20) CHECK (collection_method IN ('ONLINE_DOWNLOAD', 'PHYSICAL', 'EMAIL', 'DIGITAL_WALLET')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id)
);

-- 16. CERTIFICATE_VERSIONS (Audit trail of changes)
CREATE TABLE certificate_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    file_hash VARCHAR(64),
    file_path TEXT,
    reason VARCHAR(100) CHECK (reason IN ('INITIAL', 'CORRECTION', 'REPLACEMENT', 'UPDATED_TEMPLATE', 'REVOCATION')),
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 17. DIGITAL_SIGNATURES (Cryptographic signing)
CREATE TABLE digital_signatures (
    signature_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    signer_id UUID NOT NULL REFERENCES users(user_id),
    signing_certificate VARCHAR(100), -- Certificate used for signing
    signature_value TEXT, -- The actual cryptographic signature
    signature_algorithm VARCHAR(50) DEFAULT 'RSA-SHA256',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_valid BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMP,
    revoked_by UUID REFERENCES users(user_id),
    revocation_reason TEXT
);

-- 18. REPLACEMENTS (For lost/damaged certificates)
CREATE TABLE replacements (
    replacement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    replacement_certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    reason VARCHAR(100) CHECK (reason IN ('LOST', 'DAMAGED', 'NAME_CHANGE', 'ERROR_CORRECTION', 'OTHER')),
    reason_details TEXT,
    fee_paid BOOLEAN DEFAULT FALSE,
    fee_amount DECIMAL(10,2),
    payment_reference VARCHAR(50),
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- VERIFICATION SYSTEM
-- =============================================

-- 19. VERIFICATION_LOGS (Every verification attempt)
CREATE TABLE verification_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    verification_code VARCHAR(20) NOT NULL,
    verifier_ip INET,
    verifier_user_agent TEXT,
    verification_method VARCHAR(20) CHECK (verification_method IN ('QR_CODE', 'MANUAL_CODE', 'API', 'PORTAL')),
    verification_result BOOLEAN NOT NULL,
    failure_reason TEXT,
    verifier_email VARCHAR(255),
    verification_metadata JSONB, -- Additional context
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 20. VERIFICATION_REQUESTS (Formal verification requests from employers/agencies)
CREATE TABLE verification_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    requester_name VARCHAR(200) NOT NULL,
    requester_email VARCHAR(255) NOT NULL,
    requester_organization VARCHAR(200),
    verification_purpose TEXT,
    status VARCHAR(20) CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')),
    approval_reference VARCHAR(50),
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 21. EMPLOYERS (For verification tracking)
CREATE TABLE employers (
    employer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    registration_number VARCHAR(50),
    email_domain VARCHAR(100), -- For auto-verification
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    address TEXT,
    is_verified_entity BOOLEAN DEFAULT FALSE,
    verification_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- FINANCE & PAYMENTS
-- =============================================

-- 22. PAYMENTS
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    payment_reference VARCHAR(50) UNIQUE NOT NULL,
    payment_type VARCHAR(50) CHECK (payment_type IN ('TUITION', 'EXAM', 'CERTIFICATE_REPLACEMENT', 'TRANSCRIPT', 'VERIFICATION', 'FINE', 'OTHER')),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KES',
    payment_method VARCHAR(30) CHECK (payment_method IN ('MPESA', 'BANK_TRANSFER', 'CREDIT_CARD', 'CASH', 'SCHOLARSHIP')),
    transaction_id VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED', 'PARTIAL')),
    payment_date DATE,
    receipt_url TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- APPROVAL WORKFLOW
-- =============================================

-- 23. APPROVALS (Workflow engine for approvals)
CREATE TABLE approvals (
    approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL, -- e.g., 'CERTIFICATE', 'GRADUATION_LIST', 'REPLACEMENT'
    entity_id UUID NOT NULL, -- ID of the entity being approved
    workflow_step VARCHAR(100) NOT NULL,
    approver_id UUID NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'DELEGATED', 'CANCELLED')),
    comments TEXT,
    approval_level INTEGER NOT NULL,
    deadline DATE,
    approved_at TIMESTAMP,
    rejected_at TIMESTAMP,
    delegation_to UUID REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- NOTIFICATIONS SYSTEM
-- =============================================

-- 24. NOTIFICATIONS
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type VARCHAR(30) CHECK (type IN ('EMAIL', 'SMS', 'PUSH', 'IN_APP')),
    category VARCHAR(50) CHECK (category IN ('CERTIFICATE_READY', 'VERIFICATION', 'APPROVAL', 'PAYMENT', 'REMINDER', 'SYSTEM_ALERT')),
    subject VARCHAR(255),
    message TEXT,
    priority VARCHAR(10) CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
    status VARCHAR(20) CHECK (status IN ('QUEUED', 'SENT', 'DELIVERED', 'READ', 'FAILED')),
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- AUDIT & LOGGING
-- =============================================

-- 25. AUDIT_LOGS (Complete audit trail)
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    was_successful BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 26. ACCESS_LOGS (User session tracking)
CREATE TABLE access_logs (
    access_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    session_id UUID,
    action VARCHAR(50) CHECK (action IN ('LOGIN', 'LOGOUT', 'PAGE_VIEW', 'API_CALL', 'DOWNLOAD')),
    resource TEXT,
    ip_address INET,
    user_agent TEXT,
    duration_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ARCHIVING & PRESERVATION
-- =============================================

-- 27. ARCHIVED_DOCUMENTS (Permanent storage)
CREATE TABLE archived_documents (
    archive_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_id UUID NOT NULL REFERENCES certificates(certificate_id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(50),
    archive_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    retention_period_years INTEGER NOT NULL,
    expected_purge_date DATE,
    storage_location VARCHAR(100),
    is_worm_compliant BOOLEAN DEFAULT TRUE, -- Write Once Read Many
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ATTACHMENTS & MEDIA
-- =============================================

-- 28. ATTACHMENTS (Supporting documents)
CREATE TABLE attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL, -- e.g., 'STUDENT', 'CERTIFICATE', 'VERIFICATION_REQUEST'
    entity_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_hash VARCHAR(64),
    file_size_bytes BIGINT,
    mime_type VARCHAR(50),
    description TEXT,
    uploaded_by UUID REFERENCES users(user_id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_confidential BOOLEAN DEFAULT FALSE
);

-- =============================================
-- ROLES & PERMISSIONS (RBAC)
-- =============================================

-- 29. ROLES
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 30. PERMISSIONS
CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource VARCHAR(50) NOT NULL, -- e.g., 'CERTIFICATE', 'STUDENT', 'USER'
    action VARCHAR(50) NOT NULL, -- e.g., 'CREATE', 'READ', 'UPDATE', 'DELETE', 'VERIFY'
    description TEXT,
    UNIQUE(resource, action)
);

-- 31. USER_ROLES (User to Role mapping)
CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(user_id),
    expires_at TIMESTAMP,
    UNIQUE(user_id, role_id)
);

-- 32. ROLE_PERMISSIONS (Role to Permission mapping)
CREATE TABLE role_permissions (
    role_permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
    UNIQUE(role_id, permission_id)
);

-- =============================================
-- SYSTEM CONFIGURATION
-- =============================================

-- 33. SYSTEM_CONFIG (Application settings)
CREATE TABLE system_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) CHECK (config_type IN ('STRING', 'INTEGER', 'BOOLEAN', 'JSON')),
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(user_id)
);

-- =============================================
-- SESSION MANAGEMENT
-- =============================================

-- 34. SESSIONS
CREATE TABLE sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- This will be in a separate file, but here's a preview
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_students_student_number ON students(student_number);
CREATE INDEX idx_certificates_verification_code ON certificates(verification_code);
CREATE INDEX idx_certificates_certificate_number ON certificates(certificate_number);
CREATE INDEX idx_certificates_student_id ON certificates(student_id);
CREATE INDEX idx_certificates_status ON certificates(status);
CREATE INDEX idx_verification_logs_certificate_id ON verification_logs(certificate_id);
CREATE INDEX idx_verification_logs_created_at ON verification_logs(created_at);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_approvals_entity ON approvals(entity_type, entity_id);
CREATE INDEX idx_approvals_approver_id ON approvals(approver_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(session_token);

-- =============================================
-- CREATE VIEWS FOR COMMON QUERIES
-- =============================================

-- This will also be in a separate file
CREATE VIEW vw_student_certificates AS
SELECT 
    s.student_id,
    s.student_number,
    u.first_name,
    u.last_name,
    c.certificate_id,
    c.certificate_number,
    c.verification_code,
    c.issue_date,
    c.status,
    p.name as programme_name,
    ct.document_type
FROM certificates c
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
JOIN graduation_list_students gls ON c.graduation_list_student_id = gls.graduation_list_student_id
JOIN student_programmes sp ON gls.student_programme_id = sp.student_programme_id
JOIN programmes p ON sp.programme_id = p.programme_id
JOIN certificate_templates ct ON c.template_id = ct.template_id;

CREATE VIEW vw_certificate_verification_details AS
SELECT 
    c.certificate_id,
    c.certificate_number,
    c.verification_code,
    c.issue_date,
    c.status,
    u.first_name,
    u.last_name,
    s.student_number,
    p.name as programme_name,
    ds.timestamp as signed_at,
    ds.signer_id,
    (SELECT COUNT(*) FROM verification_logs vl WHERE vl.certificate_id = c.certificate_id) as verification_count,
    (SELECT COUNT(*) FROM verification_logs vl WHERE vl.certificate_id = c.certificate_id AND vl.verification_result = false) as failed_verifications
FROM certificates c
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
JOIN graduation_list_students gls ON c.graduation_list_student_id = gls.graduation_list_student_id
JOIN student_programmes sp ON gls.student_programme_id = sp.student_programme_id
JOIN programmes p ON sp.programme_id = p.programme_id
LEFT JOIN digital_signatures ds ON c.certificate_id = ds.certificate_id AND ds.is_valid = true;
