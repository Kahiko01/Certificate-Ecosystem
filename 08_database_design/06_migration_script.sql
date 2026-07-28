-- =============================================
-- MASTER MIGRATION SCRIPT
-- Run this in order to set up the complete database
-- =============================================

-- 1. Create extensions
\i 01_extensions.sql

-- 2. Create all tables
\i 02_tables_and_relationships.sql

-- 3. Create indexes and constraints
\i 03_indexes_and_constraints.sql

-- 4. Create views and triggers
\i 04_views_and_triggers.sql

-- 5. Insert sample data
\i 05_sample_data.sql

-- 6. Run any additional setup scripts
-- \i 06_additional_setup.sql

-- 7. Run database optimization (VACUUM, ANALYZE, etc.)
VACUUM ANALYZE;

-- 8. Display success message
SELECT 'Database migration completed successfully!' as status;

-- =============================================
-- ROLLBACK SCRIPT (for emergency)
-- =============================================

-- CREATE OR REPLACE FUNCTION rollback_migration()
-- RETURNS TEXT AS $$
-- BEGIN
--     DROP SCHEMA IF EXISTS university_certificate_ecosystem CASCADE;
--     RETURN 'Rollback completed';
-- END;
-- $$ LANGUAGE plpgsql;
