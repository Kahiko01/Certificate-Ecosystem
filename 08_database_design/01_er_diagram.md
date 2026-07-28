erDiagram
    USERS ||--o{ STUDENTS : "is"
    USERS ||--o{ EMPLOYEES : "is"
    USERS ||--o{ AUDIT_LOGS : "generates"
    
    STUDENTS ||--o{ STUDENT_PROGRAMMES : "enrolled in"
    PROGRAMMES ||--o{ STUDENT_PROGRAMMES : "contains"
    PROGRAMMES ||--o{ COURSES : "has"
    FACULTIES ||--o{ DEPARTMENTS : "has"
    DEPARTMENTS ||--o{ PROGRAMMES : "offers"
    DEPARTMENTS ||--o{ EMPLOYEES : "employs"
    
    STUDENT_PROGRAMMES ||--o{ COURSE_REGISTRATIONS : "has"
    COURSES ||--o{ COURSE_REGISTRATIONS : "includes"
    COURSE_REGISTRATIONS ||--o{ ASSESSMENTS : "has"
    COURSE_REGISTRATIONS ||--o{ EXAMINATIONS : "has"
    
    STUDENT_PROGRAMMES ||--o{ GRADUATION_LISTS : "on"
    GRADUATION_LISTS ||--o{ CERTIFICATES : "generates"
    CERTIFICATES ||--|| CERTIFICATE_TEMPLATES : "uses"
    CERTIFICATES ||--o{ CERTIFICATE_VERSIONS : "has"
    CERTIFICATES ||--o{ DIGITAL_SIGNATURES : "has"
    CERTIFICATES ||--o{ VERIFICATION_LOGS : "verified by"
    
    USERS ||--o{ APPROVALS : "approves"
    CERTIFICATES ||--o{ APPROVALS : "requires"
    
    STUDENTS ||--o{ PAYMENTS : "makes"
    PAYMENTS ||--o{ CERTIFICATES : "pays for"
    
    CERTIFICATES ||--o{ REPLACEMENTS : "has"
    CERTIFICATES ||--o{ ARCHIVED_DOCUMENTS : "archived as"
    
    EMPLOYERS ||--o{ VERIFICATION_REQUESTS : "make"
    VERIFICATION_REQUESTS ||--o{ VERIFICATION_LOGS : "generates"
    
    USERS ||--o{ NOTIFICATIONS : "receives"
    
    ROLES ||--o{ USER_ROLES : "assigned to"
    USERS ||--o{ USER_ROLES : "has"
    PERMISSIONS ||--o{ ROLE_PERMISSIONS : "granted to"
    ROLES ||--o{ ROLE_PERMISSIONS : "has"
