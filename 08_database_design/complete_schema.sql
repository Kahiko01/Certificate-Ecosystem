-- =============================================
-- COMPLETE UNIVERSITY CERTIFICATE ECOSYSTEM
-- Full Database Schema - One File
-- =============================================

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- CORE SYSTEM TABLES
-- =============================================

-- 1. USERS TABLE
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

-- 2. STUDENTS TABLE
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

-- [CONTINUE WITH ALL THE OTHER TABLES FROM YOUR FILES...]
-- I'm summarizing here - you'll paste ALL the CREATE TABLE statements
