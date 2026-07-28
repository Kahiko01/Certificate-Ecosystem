-- =============================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================

-- Students
CREATE INDEX idx_students_user_id ON students(user_id);
CREATE INDEX idx_students_status ON students(current_status);
CREATE INDEX idx_students_admission_date ON students(admission_date);
CREATE INDEX idx_students_mode_of_study ON students(mode_of_study);

-- Programmes & Courses
CREATE INDEX idx_programmes_department_id ON programmes(department_id);
CREATE INDEX idx_programmes_level ON programmes(level);
CREATE INDEX idx_courses_department_id ON courses(department_id);
CREATE INDEX idx_courses_code ON courses(code);

-- Student Programmes
CREATE INDEX idx_student_programmes_student_id ON student_programmes(student_id);
CREATE INDEX idx_student_programmes_programme_id ON student_programmes(programme_id);
CREATE INDEX idx_student_programmes_status ON student_programmes(status);

-- Course Registrations
CREATE INDEX idx_course_registrations_student_programme ON course_registrations(student_programme_id);
CREATE INDEX idx_course_registrations_course ON course_registrations(course_id);
CREATE INDEX idx_course_registrations_semester ON course_registrations(academic_year, semester);

-- Graduation Lists
CREATE INDEX idx_graduation_lists_status ON graduation_lists(status);
CREATE INDEX idx_graduation_lists_date ON graduation_lists(graduation_date);
CREATE INDEX idx_graduation_list_students_list ON graduation_list_students(graduation_list_id);
CREATE INDEX idx_graduation_list_students_clearance ON graduation_list_students(clearance_status);

-- Certificates
CREATE INDEX idx_certificates_student_date ON certificates(student_id, issue_date);
CREATE INDEX idx_certificates_collection_method ON certificates(collection_method);
CREATE INDEX idx_certificates_status_issue ON certificates(status, issue_date);

-- Verification
CREATE INDEX idx_verification_logs_date ON verification_logs(created_at);
CREATE INDEX idx_verification_logs_code ON verification_logs(verification_code);
CREATE INDEX idx_verification_requests_certificate ON verification_requests(certificate_id);

-- Payments
CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_date ON payments(payment_date);

-- Approvals
CREATE INDEX idx_approvals_entity_id ON approvals(entity_id);
CREATE INDEX idx_approvals_status_level ON approvals(status, approval_level);

-- =============================================
-- CONSTRAINTS & VALIDATIONS
-- =============================================

-- Ensure valid date ranges
ALTER TABLE students ADD CONSTRAINT chk_student_dates 
    CHECK (admission_date <= expected_graduation_date OR expected_graduation_date IS NULL);

ALTER TABLE student_programmes ADD CONSTRAINT chk_programme_dates 
    CHECK (registration_date <= expected_completion_date OR expected_completion_date IS NULL);

-- Ensure valid scores
ALTER TABLE assessments ADD CONSTRAINT chk_assessment_score 
    CHECK (score >= 0 AND score <= 100);

ALTER TABLE examinations ADD CONSTRAINT chk_exam_score 
    CHECK (score >= 0 AND score <= 100);

ALTER TABLE course_registrations ADD CONSTRAINT chk_final_score 
    CHECK (final_score IS NULL OR (final_score >= 0 AND final_score <= 100));

-- Ensure weights add up to 100 for assessments+exams (will be enforced by application logic)
-- but we can add a partial constraint

-- Prevent duplicate certificates
ALTER TABLE certificates ADD CONSTRAINT uk_certificate_number UNIQUE (certificate_number);

-- Ensure verification_code uniqueness
ALTER TABLE certificates ADD CONSTRAINT uk_verification_code UNIQUE (verification_code);

-- File hash must be valid if file_path exists
ALTER TABLE certificates ADD CONSTRAINT chk_file_hash 
    CHECK ((file_path IS NULL AND file_hash IS NULL) OR (file_path IS NOT NULL AND file_hash IS NOT NULL));

-- =============================================
-- PARTITIONING STRATEGY (for large tables)
-- =============================================

-- For the audit_logs table, we can partition by year for better performance
-- This is a concept; actual implementation depends on PostgreSQL version

-- CREATE TABLE audit_logs_partitioned (
--     LIKE audit_logs INCLUDING ALL
-- ) PARTITION BY RANGE (created_at);

-- CREATE TABLE audit_logs_2024 PARTITION OF audit_logs_partitioned
--     FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- CREATE TABLE audit_logs_2025 PARTITION OF audit_logs_partitioned
--     FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Similarly for verification_logs
-- CREATE TABLE verification_logs_partitioned (
--     LIKE verification_logs INCLUDING ALL
-- ) PARTITION BY RANGE (created_at);
