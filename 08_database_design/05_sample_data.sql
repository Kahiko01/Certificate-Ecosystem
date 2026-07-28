-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert some sample roles
INSERT INTO roles (role_id, name, description, is_system_role) VALUES
    (uuid_generate_v4(), 'SUPER_ADMIN', 'System Administrator with full access', TRUE),
    (uuid_generate_v4(), 'REGISTRAR', 'Registrar office staff', TRUE),
    (uuid_generate_v4(), 'DEAN', 'Faculty Dean', TRUE),
    (uuid_generate_v4(), 'HOD', 'Head of Department', TRUE),
    (uuid_generate_v4(), 'LECTURER', 'Teaching staff', TRUE),
    (uuid_generate_v4(), 'STUDENT', 'Enrolled student', TRUE),
    (uuid_generate_v4(), 'ALUMNI', 'Graduated student', TRUE),
    (uuid_generate_v4(), 'FINANCE_OFFICER', 'Finance department staff', TRUE),
    (uuid_generate_v4(), 'AUDITOR', 'Internal audit', TRUE),
    (uuid_generate_v4(), 'ICT_ADMIN', 'ICT department administrator', TRUE);

-- Insert sample permissions
INSERT INTO permissions (resource, action, description) VALUES
    ('CERTIFICATE', 'CREATE', 'Generate new certificates'),
    ('CERTIFICATE', 'READ', 'View certificate details'),
    ('CERTIFICATE', 'UPDATE', 'Update certificate information'),
    ('CERTIFICATE', 'DELETE', 'Delete or revoke certificates'),
    ('CERTIFICATE', 'VERIFY', 'Verify certificate authenticity'),
    ('STUDENT', 'CREATE', 'Create student records'),
    ('STUDENT', 'READ', 'View student information'),
    ('STUDENT', 'UPDATE', 'Update student records'),
    ('STUDENT', 'DELETE', 'Delete student records'),
    ('USER', 'CREATE', 'Create user accounts'),
    ('USER', 'READ', 'View user information'),
    ('USER', 'UPDATE', 'Update user accounts'),
    ('USER', 'DELETE', 'Delete user accounts'),
    ('REPORT', 'GENERATE', 'Generate system reports'),
    ('PAYMENT', 'PROCESS', 'Process payments'),
    ('PAYMENT', 'READ', 'View payment records'),
    ('VERIFICATION', 'REQUEST', 'Request certificate verification'),
    ('VERIFICATION', 'APPROVE', 'Approve verification requests'),
    ('SYSTEM', 'CONFIGURE', 'Configure system settings'),
    ('SYSTEM', 'MONITOR', 'Monitor system health');

-- Sample Faculty
INSERT INTO faculties (faculty_id, code, name, description, is_active) VALUES
    (uuid_generate_v4(), 'FICT', 'Faculty of Information and Communication Technology', 'Computing and IT Programs', TRUE),
    (uuid_generate_v4(), 'FBE', 'Faculty of Business and Economics', 'Business and Economics Programs', TRUE),
    (uuid_generate_v4(), 'FHE', 'Faculty of Health Sciences', 'Health and Medical Programs', TRUE);

-- Sample Departments
INSERT INTO departments (department_id, faculty_id, code, name, description, is_active) VALUES
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FICT'), 'CS', 'Department of Computer Science', 'Computer Science and Software Engineering', TRUE),
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FICT'), 'IS', 'Department of Information Systems', 'Information Systems and Business IT', TRUE),
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FBE'), 'FIN', 'Department of Finance', 'Finance and Investment', TRUE),
    (uuid_generate_v4(), (SELECT faculty_id FROM faculties WHERE code = 'FBE'), 'MK', 'Department of Marketing', 'Marketing and Strategic Management', TRUE);

-- Sample Programmes
INSERT INTO programmes (programme_id, department_id, code, name, level, duration_years, credit_units_required, is_active) VALUES
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'BSCS', 'Bachelor of Science in Computer Science', 'BACHELORS', 4, 120, TRUE),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'MSCS', 'Master of Science in Computer Science', 'MASTERS', 2, 60, TRUE),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'IS'), 'BBIT', 'Bachelor of Business Information Technology', 'BACHELORS', 4, 120, TRUE),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'FIN'), 'BFIN', 'Bachelor of Finance', 'BACHELORS', 4, 120, TRUE);

-- Sample Certificate Templates
INSERT INTO certificate_templates (template_id, name, document_type, template_html, template_pdf_settings, version, is_active) VALUES
    (uuid_generate_v4(), 'BSc Computer Science Template', 'DEGREE', 
     '<html><body><h1>University Certificate</h1><p>Student: {student_name}</p><p>Programme: {programme_name}</p><p>Date: {issue_date}</p></body></html>',
     '{"page_size": "A4", "orientation": "portrait", "margin": {"top": 20, "bottom": 20, "left": 20, "right": 20}}'::JSONB,
     1, TRUE),
    (uuid_generate_v4(), 'Official Transcript Template', 'TRANSCRIPT',
     '<html><body><h1>Academic Transcript</h1><p>Student: {student_name}</p><p>Programme: {programme_name}</p><table>...</table></body></html>',
     '{"page_size": "A4", "orientation": "portrait"}'::JSONB,
     1, TRUE);

-- Sample Users (password: hashed 'password123')
INSERT INTO users (user_id, username, email, password_hash, first_name, last_name, is_active) VALUES
    (uuid_generate_v4(), 'admin', 'admin@university.ac.ke', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewd5dLzZvJWQrP3G', 'System', 'Administrator', TRUE),
    (uuid_generate_v4(), 'registrar', 'registrar@university.ac.ke', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewd5dLzZvJWQrP3G', 'Jane', 'Registrar', TRUE),
    (uuid_generate_v4(), 'dean.fict', 'dean.fict@university.ac.ke', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewd5dLzZvJWQrP3G', 'John', 'DeanFICT', TRUE),
    (uuid_generate_v4(), 'student1', 'student1@university.ac.ke', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewd5dLzZvJWQrP3G', 'Alice', 'Student', TRUE);

-- Sample Students
INSERT INTO students (student_id, user_id, student_number, admission_date, current_status, mode_of_study, is_international) VALUES
    (uuid_generate_v4(), (SELECT user_id FROM users WHERE username = 'student1'), 'S20240001', '2024-09-01', 'ACTIVE', 'FULL_TIME', FALSE);

-- Sample Student Programmes
INSERT INTO student_programmes (student_programme_id, student_id, programme_id, registration_date, expected_completion_date, status, academic_year, intake) VALUES
    (uuid_generate_v4(), 
     (SELECT student_id FROM students WHERE student_number = 'S20240001'),
     (SELECT programme_id FROM programmes WHERE code = 'BSCS'),
     '2024-09-01', '2028-06-01', 'ACTIVE', 2024, 'SEPTEMBER');

-- Sample Courses
INSERT INTO courses (course_id, department_id, code, name, credit_units, course_type, semester_offered, year_offered, is_active) VALUES
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'CSC101', 'Introduction to Computer Science', 3, 'CORE', 1, 1, TRUE),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'CSC102', 'Programming Fundamentals', 3, 'CORE', 1, 1, TRUE),
    (uuid_generate_v4(), (SELECT department_id FROM departments WHERE code = 'CS'), 'CSC201', 'Data Structures and Algorithms', 3, 'CORE', 1, 2, TRUE);

-- Sample Course Registrations
INSERT INTO course_registrations (registration_id, student_programme_id, course_id, academic_year, semester, registration_date, status) VALUES
    (uuid_generate_v4(),
     (SELECT student_programme_id FROM student_programmes LIMIT 1),
     (SELECT course_id FROM courses WHERE code = 'CSC101'),
     2024, 1, '2024-09-01', 'REGISTERED'),
    (uuid_generate_v4(),
     (SELECT student_programme_id FROM student_programmes LIMIT 1),
     (SELECT course_id FROM courses WHERE code = 'CSC102'),
     2024, 1, '2024-09-01', 'REGISTERED');

-- Sample System Config
INSERT INTO system_config (config_key, config_value, config_type, description) VALUES
    ('verification_code_length', '6', 'INTEGER', 'Length of verification code to generate'),
    ('certificate_retention_years', '75', 'INTEGER', 'How long to retain certificates after graduation'),
    ('require_2fa_for_verification', 'false', 'BOOLEAN', 'Require 2FA for certificate verification'),
    ('max_verification_requests_per_day', '100', 'INTEGER', 'Maximum verification requests per day'),
    ('smtp_host', 'smtp.university.ac.ke', 'STRING', 'SMTP server for email notifications'),
    ('email_from', 'noreply@university.ac.ke', 'STRING', 'Default email sender address');
