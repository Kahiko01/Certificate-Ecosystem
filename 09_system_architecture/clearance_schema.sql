-- =============================================
-- CLEARANCE SYSTEM TABLES
-- =============================================

-- 1. CLEARANCE_DEPARTMENTS
CREATE TABLE IF NOT EXISTS clearance_departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    clearance_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. CLEARANCE_REQUIREMENTS
CREATE TABLE IF NOT EXISTS clearance_requirements (
    requirement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES clearance_departments(department_id),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. STUDENT_CLEARANCE
CREATE TABLE IF NOT EXISTS student_clearance (
    clearance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES clearance_departments(department_id),
    status VARCHAR(20) CHECK (status IN ('PENDING', 'CLEARED', 'NOT_CLEARED', 'FLAGGED')),
    cleared_by UUID REFERENCES users(user_id),
    cleared_at TIMESTAMP,
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, department_id)
);

-- 4. STUDENT_ACADEMIC_STATUS
CREATE TABLE IF NOT EXISTS student_academic_status (
    status_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    programme_id UUID NOT NULL REFERENCES programmes(programme_id),
    total_credits_required INTEGER NOT NULL,
    total_credits_earned INTEGER DEFAULT 0,
    total_credits_remaining INTEGER DEFAULT 0,
    courses_passed INTEGER DEFAULT 0,
    courses_failed INTEGER DEFAULT 0,
    courses_remaining INTEGER DEFAULT 0,
    gpa DECIMAL(4,2),
    is_eligible_for_graduation BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, programme_id)
);

-- 5. FINANCIAL_CLEARANCE
CREATE TABLE IF NOT EXISTS financial_clearance (
    financial_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    academic_year INTEGER NOT NULL,
    semester INTEGER CHECK (semester IN (1, 2, 3)),
    total_fees_due DECIMAL(12,2) NOT NULL,
    total_fees_paid DECIMAL(12,2) DEFAULT 0,
    balance DECIMAL(12,2) DEFAULT 0,
    is_cleared BOOLEAN DEFAULT FALSE,
    cleared_by UUID REFERENCES users(user_id),
    cleared_at TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, academic_year, semester)
);

-- 6. GRADUATION_CHECKLIST
CREATE TABLE IF NOT EXISTS graduation_checklist (
    checklist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    academic_clearance BOOLEAN DEFAULT FALSE,
    financial_clearance BOOLEAN DEFAULT FALSE,
    library_clearance BOOLEAN DEFAULT FALSE,
    accommodation_clearance BOOLEAN DEFAULT FALSE,
    disciplinary_clearance BOOLEAN DEFAULT FALSE,
    registry_clearance BOOLEAN DEFAULT FALSE,
    senate_approval BOOLEAN DEFAULT FALSE,
    is_complete BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id)
);

-- 7. CLEARANCE_AUDIT_LOGS
CREATE TABLE IF NOT EXISTS clearance_audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(student_id),
    department_id UUID NOT NULL REFERENCES clearance_departments(department_id),
    action VARCHAR(50) NOT NULL,
    status_from VARCHAR(20),
    status_to VARCHAR(20),
    performed_by UUID REFERENCES users(user_id),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert clearance departments
INSERT INTO clearance_departments (department_id, code, name, description, clearance_order) VALUES
    (uuid_generate_v4(), 'FINANCE', 'Finance Department', 'Clears students with no fee balance', 1),
    (uuid_generate_v4(), 'ACADEMIC', 'Academic Registry', 'Checks academic requirements completion', 2),
    (uuid_generate_v4(), 'LIBRARY', 'Library Services', 'Checks for borrowed books and fines', 3),
    (uuid_generate_v4(), 'ACCOMMODATION', 'Accommodation Office', 'Clears accommodation fees and damages', 4),
    (uuid_generate_v4(), 'DISCIPLINE', 'Disciplinary Committee', 'Checks for any disciplinary issues', 5),
    (uuid_generate_v4(), 'REGISTRY', 'Registry Office', 'Final verification of all requirements', 6),
    (uuid_generate_v4(), 'SENATE', 'Senate Office', 'Final approval for graduation', 7)
ON CONFLICT (code) DO NOTHING;
