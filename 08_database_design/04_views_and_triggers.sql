-- =============================================
-- USEFUL VIEWS FOR REPORTING
-- =============================================

-- 1. Certificate Issuance Summary
CREATE VIEW vw_certificate_issuance_summary AS
SELECT 
    DATE_TRUNC('month', issue_date) as month,
    document_type,
    COUNT(*) as certificates_issued,
    COUNT(CASE WHEN status = 'COLLECTED' THEN 1 END) as collected,
    COUNT(CASE WHEN status = 'ISSUED' THEN 1 END) as pending_collection,
    COUNT(CASE WHEN status = 'REVOKED' THEN 1 END) as revoked,
    COUNT(CASE WHEN status = 'REPLACED' THEN 1 END) as replaced
FROM certificates c
JOIN certificate_templates ct ON c.template_id = ct.template_id
GROUP BY DATE_TRUNC('month', issue_date), document_type
ORDER BY month DESC, document_type;

-- 2. Student Academic Summary
CREATE VIEW vw_student_academic_summary AS
SELECT 
    s.student_id,
    s.student_number,
    u.first_name,
    u.last_name,
    p.name as programme_name,
    p.level as programme_level,
    sp.status as programme_status,
    sp.registration_date,
    sp.expected_completion_date,
    sp.actual_completion_date,
    (SELECT AVG(final_score) FROM course_registrations cr 
     WHERE cr.student_programme_id = sp.student_programme_id 
     AND cr.status = 'COMPLETED') as average_score,
    (SELECT COUNT(*) FROM course_registrations cr 
     WHERE cr.student_programme_id = sp.student_programme_id 
     AND cr.status = 'COMPLETED') as courses_completed,
    (SELECT COUNT(*) FROM course_registrations cr 
     WHERE cr.student_programme_id = sp.student_programme_id) as courses_registered
FROM students s
JOIN users u ON s.user_id = u.user_id
JOIN student_programmes sp ON s.student_id = sp.student_id
JOIN programmes p ON sp.programme_id = p.programme_id
WHERE sp.status IN ('ACTIVE', 'COMPLETED');

-- 3. Verification Activity Dashboard
CREATE VIEW vw_verification_dashboard AS
SELECT 
    DATE_TRUNC('day', vl.created_at) as verification_date,
    c.certificate_number,
    CONCAT(u.first_name, ' ', u.last_name) as student_name,
    vl.verification_method,
    vl.verification_result,
    vl.verifier_ip,
    vl.created_at as verification_time,
    (SELECT COUNT(*) FROM verification_logs vl2 
     WHERE vl2.certificate_id = c.certificate_id) as total_verifications_for_certificate
FROM verification_logs vl
JOIN certificates c ON vl.certificate_id = c.certificate_id
JOIN students s ON c.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
ORDER BY vl.created_at DESC;

-- 4. Pending Approvals
CREATE VIEW vw_pending_approvals AS
SELECT 
    a.approval_id,
    a.entity_type,
    a.entity_id,
    a.workflow_step,
    a.approval_level,
    CONCAT(u.first_name, ' ', u.last_name) as approver_name,
    a.deadline,
    DATEDIFF('day', CURRENT_DATE, a.deadline) as days_until_deadline,
    CASE 
        WHEN a.created_at > NOW() - INTERVAL '30 days' THEN 'URGENT'
        ELSE 'NORMAL'
    END as priority
FROM approvals a
JOIN users u ON a.approver_id = u.user_id
WHERE a.status = 'PENDING'
ORDER BY a.deadline ASC;

-- 5. Financial Summary
CREATE VIEW vw_financial_summary AS
SELECT 
    DATE_TRUNC('month', payment_date) as month,
    payment_type,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as average_amount,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_transactions
FROM payments
WHERE status IN ('COMPLETED', 'PENDING', 'FAILED')
GROUP BY DATE_TRUNC('month', payment_date), payment_type
ORDER BY month DESC, payment_type;

-- =============================================
-- TRIGGERS FOR AUTOMATION
-- =============================================

-- 1. Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_certificates_updated_at BEFORE UPDATE ON certificates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Generate verification code when certificate is created
CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TRIGGER AS $$
DECLARE
    code_part1 TEXT;
    code_part2 TEXT;
    code_part3 TEXT;
BEGIN
    -- Generate a 6-character alphanumeric code
    code_part1 := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 2));
    code_part2 := TO_CHAR(FLOOR(RANDOM() * 10000)::INTEGER, 'FM0000');
    code_part3 := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 2));
    
    NEW.verification_code := code_part1 || '-' || code_part2 || '-' || code_part3;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_verification_code BEFORE INSERT ON certificates
    FOR EACH ROW
    WHEN (NEW.verification_code IS NULL)
    EXECUTE FUNCTION generate_verification_code();

-- 3. Auto-generate certificate number if not provided
CREATE OR REPLACE FUNCTION generate_certificate_number()
RETURNS TRIGGER AS $$
DECLARE
    year_part TEXT;
    seq_part TEXT;
BEGIN
    year_part := TO_CHAR(NEW.issue_date, 'YYYY');
    -- Get next sequence value
    seq_part := TO_CHAR(NEXTVAL('certificate_number_seq'), 'FM000000');
    NEW.certificate_number := 'UCERT-' || year_part || '-' || seq_part;
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

-- 4. Audit trigger for critical tables
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (
            user_id,
            action,
            entity_type,
            entity_id,
            old_values,
            new_values,
            ip_address,
            user_agent
        ) VALUES (
            current_setting('app.current_user_id', TRUE)::UUID,
            'UPDATE',
            TG_TABLE_NAME,
            NEW.certificate_id,  -- Adjust based on table
            row_to_json(OLD),
            row_to_json(NEW),
            current_setting('app.current_ip', TRUE)::INET,
            current_setting('app.current_user_agent', TRUE)
        );
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (
            user_id,
            action,
            entity_type,
            entity_id,
            new_values,
            ip_address,
            user_agent
        ) VALUES (
            current_setting('app.current_user_id', TRUE)::UUID,
            'INSERT',
            TG_TABLE_NAME,
            NEW.certificate_id,
            row_to_json(NEW),
            current_setting('app.current_ip', TRUE)::INET,
            current_setting('app.current_user_agent', TRUE)
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (
            user_id,
            action,
            entity_type,
            entity_id,
            old_values,
            ip_address,
            user_agent
        ) VALUES (
            current_setting('app.current_user_id', TRUE)::UUID,
            'DELETE',
            TG_TABLE_NAME,
            OLD.certificate_id,
            row_to_json(OLD),
            current_setting('app.current_ip', TRUE)::INET,
            current_setting('app.current_user_agent', TRUE)
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply audit trigger to certificates table
CREATE TRIGGER audit_certificates AFTER INSERT OR UPDATE OR DELETE ON certificates
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- 5. Update student status when all course registrations are completed
CREATE OR REPLACE FUNCTION update_student_programme_status()
RETURNS TRIGGER AS $$
DECLARE
    total_courses INTEGER;
    completed_courses INTEGER;
BEGIN
    -- Only proceed if a course registration was updated to COMPLETED or FAILED
    IF NEW.status IN ('COMPLETED', 'FAILED') AND OLD.status != NEW.status THEN
        -- Count total courses for this student programme
        SELECT COUNT(*) INTO total_courses 
        FROM course_registrations 
        WHERE student_programme_id = NEW.student_programme_id;
        
        -- Count completed or failed courses
        SELECT COUNT(*) INTO completed_courses 
        FROM course_registrations 
        WHERE student_programme_id = NEW.student_programme_id 
        AND status IN ('COMPLETED', 'FAILED');
        
        -- If all courses are completed/failed, update programme status
        IF total_courses = completed_courses THEN
            UPDATE student_programmes 
            SET status = 'COMPLETED',
                actual_completion_date = CURRENT_DATE
            WHERE student_programme_id = NEW.student_programme_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_student_programme_completion AFTER UPDATE ON course_registrations
    FOR EACH ROW EXECUTE FUNCTION update_student_programme_status();
