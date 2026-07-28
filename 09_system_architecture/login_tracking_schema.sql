-- =============================================
-- LOGIN TRACKING & SESSION MANAGEMENT
-- =============================================

-- 1. LOGIN_HISTORY (Track all login attempts)
CREATE TABLE IF NOT EXISTS login_history (
    login_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    username VARCHAR(50) NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    session_duration_seconds INTEGER,
    ip_address INET,
    user_agent TEXT,
    login_status VARCHAR(20) CHECK (login_status IN ('SUCCESS', 'FAILED', 'LOGGED_OUT', 'EXPIRED')),
    failure_reason TEXT,
    session_id UUID,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    os VARCHAR(50),
    location_city VARCHAR(100),
    location_country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. ACTIVE_SESSIONS (Currently logged in users)
CREATE TABLE IF NOT EXISTS active_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) NOT NULL,
    username VARCHAR(50) NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(50),
    browser VARCHAR(50),
    os VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    token_refresh_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. LOGIN_STATS (Daily login statistics)
CREATE TABLE IF NOT EXISTS login_stats (
    stat_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stat_date DATE NOT NULL,
    total_logins INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    failed_attempts INTEGER DEFAULT 0,
    successful_logins INTEGER DEFAULT 0,
    average_session_duration INTEGER DEFAULT 0,
    peak_concurrent_users INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stat_date)
);

-- =============================================
-- CREATE INDEXES
-- =============================================

CREATE INDEX idx_login_history_user ON login_history(user_id);
CREATE INDEX idx_login_history_username ON login_history(username);
CREATE INDEX idx_login_history_login_time ON login_history(login_time);
CREATE INDEX idx_login_history_status ON login_history(login_status);

CREATE INDEX idx_active_sessions_user ON active_sessions(user_id);
CREATE INDEX idx_active_sessions_last_activity ON active_sessions(last_activity);
CREATE INDEX idx_active_sessions_is_active ON active_sessions(is_active);

CREATE INDEX idx_login_stats_date ON login_stats(stat_date);

-- =============================================
-- VIEWS FOR REPORTING
-- =============================================

-- View: Current Online Users
CREATE OR REPLACE VIEW vw_online_users AS
SELECT 
    asession.user_id,
    asession.username,
    u.first_name,
    u.last_name,
    asession.login_time,
    asession.last_activity,
    EXTRACT(EPOCH FROM (NOW() - asession.login_time))::INTEGER as session_duration_seconds,
    asession.ip_address,
    asession.device_type,
    asession.browser,
    asession.os,
    array_agg(r.name) as roles
FROM active_sessions asession
JOIN users u ON asession.user_id = u.user_id
LEFT JOIN user_roles ur ON u.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id
WHERE asession.is_active = TRUE
  AND asession.last_activity > NOW() - INTERVAL '15 minutes'
GROUP BY asession.user_id, asession.username, u.first_name, u.last_name,
         asession.login_time, asession.last_activity, asession.ip_address,
         asession.device_type, asession.browser, asession.os;

-- View: Login Activity Summary
CREATE OR REPLACE VIEW vw_login_activity_summary AS
SELECT 
    DATE(login_time) as login_date,
    COUNT(*) as total_logins,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN login_status = 'SUCCESS' THEN 1 END) as successful_logins,
    COUNT(CASE WHEN login_status = 'FAILED' THEN 1 END) as failed_logins,
    AVG(session_duration_seconds)::INTEGER as avg_session_duration
FROM login_history
WHERE login_time > NOW() - INTERVAL '30 days'
GROUP BY DATE(login_time)
ORDER BY login_date DESC;

-- View: User Login History with Details
CREATE OR REPLACE VIEW vw_user_login_history AS
SELECT 
    lh.login_id,
    lh.username,
    u.first_name,
    u.last_name,
    lh.login_time,
    lh.logout_time,
    lh.session_duration_seconds,
    lh.ip_address,
    lh.device_type,
    lh.browser,
    lh.os,
    lh.login_status,
    lh.failure_reason,
    CASE 
        WHEN lh.logout_time IS NOT NULL THEN 'Completed'
        WHEN lh.login_status = 'SUCCESS' AND lh.logout_time IS NULL THEN 'Active'
        ELSE lh.login_status
    END as session_status
FROM login_history lh
JOIN users u ON lh.user_id = u.user_id
ORDER BY lh.login_time DESC;

-- View: User Session Statistics
CREATE OR REPLACE VIEW vw_user_session_stats AS
SELECT 
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    COUNT(lh.login_id) as total_sessions,
    COUNT(CASE WHEN lh.login_status = 'SUCCESS' THEN 1 END) as successful_sessions,
    COUNT(CASE WHEN lh.login_status = 'FAILED' THEN 1 END) as failed_sessions,
    AVG(lh.session_duration_seconds)::INTEGER as avg_session_duration,
    MAX(lh.login_time) as last_login,
    MIN(lh.login_time) as first_login
FROM users u
LEFT JOIN login_history lh ON u.user_id = lh.user_id
GROUP BY u.user_id, u.username, u.first_name, u.last_name;

-- View: Today's Login Activity
CREATE OR REPLACE VIEW vw_today_login_activity AS
SELECT 
    EXTRACT(HOUR FROM login_time) as hour,
    COUNT(*) as logins,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN login_status = 'SUCCESS' THEN 1 END) as successful_logins,
    COUNT(CASE WHEN login_status = 'FAILED' THEN 1 END) as failed_logins
FROM login_history
WHERE DATE(login_time) = CURRENT_DATE
GROUP BY EXTRACT(HOUR FROM login_time)
ORDER BY hour;

