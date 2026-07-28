graph TD
    A[Applicant] --> B[Admitted: SIS]
    B --> C[Registered Student]
    C --> D[Course Enrollment]
    D --> E[Assessments & Exams]
    E --> F{Graduate?}
    F -- Yes --> G[Graduation Clearance: Depts, Finance, Library]
    G --> H[Senate Approval]
    H --> I[Certificate Generation Engine]
    I --> J[Digital Signing: PKI]
    J --> K[Certificate Issuance: Student Portal]
    K --> L[Student Digital Collection]
    L --> M[Public Verification]
    L --> N[Archiving & Preservation]
    
    F -- No --> D
    M --> O[Verification Logs]
    N --> P[Permanent Digital Vault]
