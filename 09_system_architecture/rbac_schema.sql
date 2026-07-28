-- =============================================
-- ROLE-BASED ACCESS CONTROL (RBAC) SYSTEM
-- =============================================

-- 1. ROLES TABLE
CREATE TABLE IF NOT EXISTS roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    department_code VARCHAR(20),
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. PERMISSIONS TABLE
CREATE TABLE IF NOT EXISTS permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource VARCHAR(50) NOT NULL,  -- e.g., 'certificate', 'student', 'clearance', 'user'
    action VARCHAR(50) NOT NULL,    -- e.g., 'create', 'read', 'update', 'delete', 'approve'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource, action)
);

-- 3. ROLE_PERMISSIONS TABLE (Many-to-Many)
CREATE TABLE IF NOT EXISTS role_permissions (
    role_permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_id, permission_id)
);

-- 4. USER_ROLES TABLE
CREATE TABLE IF NOT EXISTS user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(user_id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, role_id)
);

-- 5. DEPARTMENT_USERS TABLE
CREATE TABLE IF NOT EXISTS department_users (
    department_user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    department_code VARCHAR(20) NOT NULL,
    is_head BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, department_code)
);

-- =============================================
-- INSERT DEFAULT ROLES
-- =============================================

-- System Admin Roles
INSERT INTO roles (role_id, name, description, department_code, is_system_role) VALUES
    (uuid_generate_v4(), 'SYSTEM_ADMIN', 'Full system administration access', NULL, TRUE),
    (uuid_generate_v4(), 'SUPER_ADMIN', 'Super administrator with all permissions', NULL, TRUE);

-- Department Roles
INSERT INTO roles (role_id, name, description, department_code, is_system_role) VALUES
    (uuid_generate_v4(), 'FINANCE_OFFICER', 'Finance department officer', 'FINANCE', FALSE),
    (uuid_generate_v4(), 'FINANCE_HEAD', 'Head of Finance department', 'FINANCE', FALSE),
    (uuid_generate_v4(), 'ACADEMIC_OFFICER', 'Academic registry officer', 'ACADEMIC', FALSE),
    (uuid_generate_v4(), 'ACADEMIC_HEAD', 'Head of Academic registry', 'ACADEMIC', FALSE),
    (uuid_generate_v4(), 'LIBRARY_OFFICER', 'Library department officer', 'LIBRARY', FALSE),
    (uuid_generate_v4(), 'LIBRARY_HEAD', 'Head of Library department', 'LIBRARY', FALSE),
    (uuid_generate_v4(), 'ACCOMMODATION_OFFICER', 'Accommodation department officer', 'ACCOMMODATION', FALSE),
    (uuid_generate_v4(), 'ACCOMMODATION_HEAD', 'Head of Accommodation department', 'ACCOMMODATION', FALSE),
    (uuid_generate_v4(), 'DISCIPLINE_OFFICER', 'Disciplinary committee officer', 'DISCIPLINE', FALSE),
    (uuid_generate_v4(), 'DISCIPLINE_HEAD', 'Head of Disciplinary committee', 'DISCIPLINE', FALSE),
    (uuid_generate_v4(), 'REGISTRY_OFFICER', 'Registry department officer', 'REGISTRY', FALSE),
    (uuid_generate_v4(), 'REGISTRY_HEAD', 'Head of Registry department', 'REGISTRY', FALSE),
    (uuid_generate_v4(), 'SENATE_OFFICER', 'Senate office officer', 'SENATE', FALSE),
    (uuid_generate_v4(), 'SENATE_HEAD', 'Head of Senate office', 'SENATE', FALSE);

-- Registrar Roles
INSERT INTO roles (role_id, name, description, department_code, is_system_role) VALUES
    (uuid_generate_v4(), 'REGISTRAR', 'University Registrar', NULL, FALSE),
    (uuid_generate_v4(), 'DEPUTY_REGISTRAR', 'Deputy Registrar', NULL, FALSE);

-- Student and Public Roles
INSERT INTO roles (role_id, name, description, department_code, is_system_role) VALUES
    (uuid_generate_v4(), 'STUDENT', 'Enrolled student', NULL, FALSE),
    (uuid_generate_v4(), 'ALUMNI', 'Graduated student', NULL, FALSE),
    (uuid_generate_v4(), 'PUBLIC_VERIFIER', 'Public user for verification', NULL, FALSE);

-- =============================================
-- INSERT PERMISSIONS
-- =============================================

-- Certificate Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'certificate', 'create', 'Create new certificates'),
    (uuid_generate_v4(), 'certificate', 'read', 'View certificate details'),
    (uuid_generate_v4(), 'certificate', 'update', 'Update certificate information'),
    (uuid_generate_v4(), 'certificate', 'delete', 'Delete or revoke certificates'),
    (uuid_generate_v4(), 'certificate', 'verify', 'Verify certificate authenticity'),
    (uuid_generate_v4(), 'certificate', 'bulk_create', 'Bulk certificate generation');

-- Student Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'student', 'create', 'Create student records'),
    (uuid_generate_v4(), 'student', 'read', 'View student information'),
    (uuid_generate_v4(), 'student', 'update', 'Update student records'),
    (uuid_generate_v4(), 'student', 'delete', 'Delete student records'),
    (uuid_generate_v4(), 'student', 'clearance', 'Manage student clearance');

-- User Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'user', 'create', 'Create user accounts'),
    (uuid_generate_v4(), 'user', 'read', 'View user information'),
    (uuid_generate_v4(), 'user', 'update', 'Update user accounts'),
    (uuid_generate_v4(), 'user', 'delete', 'Delete user accounts'),
    (uuid_generate_v4(), 'user', 'manage_roles', 'Manage user roles and permissions');

-- Department Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'department', 'clear', 'Clear students for department'),
    (uuid_generate_v4(), 'department', 'read', 'View department clearance status'),
    (uuid_generate_v4(), 'department', 'manage', 'Manage department settings');

-- Clearance Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'clearance', 'view', 'View clearance status'),
    (uuid_generate_v4(), 'clearance', 'approve', 'Approve clearance requests'),
    (uuid_generate_v4(), 'clearance', 'reject', 'Reject clearance requests');

-- Financial Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'finance', 'view', 'View financial records'),
    (uuid_generate_v4(), 'finance', 'update', 'Update financial records'),
    (uuid_generate_v4(), 'finance', 'clear', 'Clear financial obligations');

-- Report Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'report', 'generate', 'Generate system reports'),
    (uuid_generate_v4(), 'report', 'view', 'View system reports');

-- System Permissions
INSERT INTO permissions (permission_id, resource, action, description) VALUES
    (uuid_generate_v4(), 'system', 'configure', 'Configure system settings'),
    (uuid_generate_v4(), 'system', 'monitor', 'Monitor system health'),
    (uuid_generate_v4(), 'system', 'audit', 'View audit logs');

-- =============================================
-- ASSIGN PERMISSIONS TO ROLES
-- =============================================

-- SYSTEM_ADMIN: All permissions
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'SYSTEM_ADMIN'),
    permission_id
FROM permissions;

-- SUPER_ADMIN: All permissions
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'SUPER_ADMIN'),
    permission_id
FROM permissions;

-- REGISTRAR: Certificate, Student, Clearance permissions
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'REGISTRAR'),
    permission_id
FROM permissions 
WHERE resource IN ('certificate', 'student', 'clearance', 'report');

-- FINANCE_HEAD: Finance, Student clearance
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'FINANCE_HEAD'),
    permission_id
FROM permissions 
WHERE resource IN ('finance', 'student') OR (resource = 'department' AND action = 'clear');

-- FINANCE_OFFICER: Finance view and update
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'FINANCE_OFFICER'),
    permission_id
FROM permissions 
WHERE resource = 'finance' AND action IN ('view', 'update', 'clear');

-- Department Heads: Full access to their department
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'ACADEMIC_HEAD'),
    permission_id
FROM permissions 
WHERE resource IN ('student', 'clearance', 'department');

-- Department Officers: Basic department permissions
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'ACADEMIC_OFFICER'),
    permission_id
FROM permissions 
WHERE (resource = 'department' AND action IN ('clear', 'read')) 
   OR (resource = 'student' AND action = 'read');

-- STUDENT: View own records
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'STUDENT'),
    permission_id
FROM permissions 
WHERE (resource = 'student' AND action = 'read') 
   OR (resource = 'certificate' AND action = 'read')
   OR (resource = 'certificate' AND action = 'verify');

-- PUBLIC_VERIFIER: Only verify certificates
INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT 
    uuid_generate_v4(),
    (SELECT role_id FROM roles WHERE name = 'PUBLIC_VERIFIER'),
    permission_id
FROM permissions 
WHERE resource = 'certificate' AND action = 'verify';

-- =============================================
-- CREATE DEPARTMENT USER ACCOUNTS
-- =============================================

-- System Admin Account
INSERT INTO users (user_id, username, email, password_hash, first_name, last_name, is_active)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'system_admin',
    'admin@university.ac.ke',
    'admin_hash',
    'System',
    'Administrator',
    TRUE
) ON CONFLICT (username) DO NOTHING;

-- Assign System Admin Role
INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
SELECT 
    uuid_generate_v4(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    (SELECT role_id FROM roles WHERE name = 'SYSTEM_ADMIN'),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
WHERE NOT EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    AND role_id = (SELECT role_id FROM roles WHERE name = 'SYSTEM_ADMIN')
);

-- Department Accounts
INSERT INTO users (user_id, username, email, password_hash, first_name, last_name, is_active)
VALUES
    (uuid_generate_v4(), 'finance_head', 'finance.head@university.ac.ke', 'default_hash', 'Finance', 'Head', TRUE),
    (uuid_generate_v4(), 'finance_officer', 'finance.officer@university.ac.ke', 'default_hash', 'Finance', 'Officer', TRUE),
    (uuid_generate_v4(), 'academic_head', 'academic.head@university.ac.ke', 'default_hash', 'Academic', 'Head', TRUE),
    (uuid_generate_v4(), 'academic_officer', 'academic.officer@university.ac.ke', 'default_hash', 'Academic', 'Officer', TRUE),
    (uuid_generate_v4(), 'library_head', 'library.head@university.ac.ke', 'default_hash', 'Library', 'Head', TRUE),
    (uuid_generate_v4(), 'library_officer', 'library.officer@university.ac.ke', 'default_hash', 'Library', 'Officer', TRUE),
    (uuid_generate_v4(), 'accommodation_head', 'accommodation.head@university.ac.ke', 'default_hash', 'Accommodation', 'Head', TRUE),
    (uuid_generate_v4(), 'accommodation_officer', 'accommodation.officer@university.ac.ke', 'default_hash', 'Accommodation', 'Officer', TRUE),
    (uuid_generate_v4(), 'discipline_head', 'discipline.head@university.ac.ke', 'default_hash', 'Discipline', 'Head', TRUE),
    (uuid_generate_v4(), 'discipline_officer', 'discipline.officer@university.ac.ke', 'default_hash', 'Discipline', 'Officer', TRUE),
    (uuid_generate_v4(), 'registry_head', 'registry.head@university.ac.ke', 'default_hash', 'Registry', 'Head', TRUE),
    (uuid_generate_v4(), 'registry_officer', 'registry.officer@university.ac.ke', 'default_hash', 'Registry', 'Officer', TRUE),
    (uuid_generate_v4(), 'registrar', 'registrar@university.ac.ke', 'default_hash', 'University', 'Registrar', TRUE)
ON CONFLICT (username) DO NOTHING;

-- Assign Department Head Roles
DO $$
DECLARE
    user_id UUID;
    role_id UUID;
BEGIN
    -- Finance Head
    SELECT user_id INTO user_id FROM users WHERE username = 'finance_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'FINANCE_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Finance Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'finance_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'FINANCE_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Academic Head
    SELECT user_id INTO user_id FROM users WHERE username = 'academic_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'ACADEMIC_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Academic Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'academic_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'ACADEMIC_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Library Head
    SELECT user_id INTO user_id FROM users WHERE username = 'library_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'LIBRARY_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Library Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'library_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'LIBRARY_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Accommodation Head
    SELECT user_id INTO user_id FROM users WHERE username = 'accommodation_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'ACCOMMODATION_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Accommodation Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'accommodation_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'ACCOMMODATION_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Discipline Head
    SELECT user_id INTO user_id FROM users WHERE username = 'discipline_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'DISCIPLINE_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Discipline Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'discipline_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'DISCIPLINE_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Registry Head
    SELECT user_id INTO user_id FROM users WHERE username = 'registry_head';
    SELECT role_id INTO role_id FROM roles WHERE name = 'REGISTRY_HEAD';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Registry Officer
    SELECT user_id INTO user_id FROM users WHERE username = 'registry_officer';
    SELECT role_id INTO role_id FROM roles WHERE name = 'REGISTRY_OFFICER';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
    
    -- Registrar
    SELECT user_id INTO user_id FROM users WHERE username = 'registrar';
    SELECT role_id INTO role_id FROM roles WHERE name = 'REGISTRAR';
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_by)
    SELECT uuid_generate_v4(), user_id, role_id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = user_id AND role_id = role_id);
END $$;

-- =============================================
-- VIEWS FOR EASY QUERYING
-- =============================================

-- View: User Roles with Details
CREATE OR REPLACE VIEW vw_user_roles AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    r.name as role_name,
    r.department_code,
    r.description as role_description,
    ur.assigned_at,
    ur.is_active as role_active
FROM users u
JOIN user_roles ur ON u.user_id = ur.user_id
JOIN roles r ON ur.role_id = r.role_id
WHERE ur.is_active = TRUE;

-- View: User Permissions
CREATE OR REPLACE VIEW vw_user_permissions AS
SELECT DISTINCT
    u.user_id,
    u.username,
    p.resource,
    p.action,
    p.description as permission_description
FROM users u
JOIN user_roles ur ON u.user_id = ur.user_id
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
WHERE ur.is_active = TRUE;

-- View: Department Users
CREATE OR REPLACE VIEW vw_department_users AS
SELECT 
    du.department_user_id,
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    du.department_code,
    du.is_head,
    r.name as role_name
FROM department_users du
JOIN users u ON du.user_id = u.user_id
LEFT JOIN user_roles ur ON u.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id
WHERE ur.is_active = TRUE;

