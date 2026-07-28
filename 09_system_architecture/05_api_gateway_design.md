      middlewares:
        - name: public-rate-limit
        - name: cors-public
        - name: cache-response

    # Student Management Routes
    - kind: Rule
      match: Host(`api.university.ac.ke`) && PathPrefix(`/students`)
      services:
        - name: student-service
          port: 8080
      middlewares:
        - name: auth-jwt
        - name: rate-limit
        - name: audit-log

    # Payment Routes
    - kind: Rule
      match: Host(`api.university.ac.ke`) && PathPrefix(`/payments`)
      services:
        - name: payment-service
          port: 8080
      middlewares:
        - name: auth-jwt
        - name: rate-limit
        - name: payment-validation

    # Admin Routes
    - kind: Rule
      match: Host(`admin.university.ac.ke`) && PathPrefix(`/admin`)
      services:
        - name: admin-service
          port: 8080
      middlewares:
        - name: auth-jwt
        - name: admin-check
        - name: rate-limit
        - name: audit-log

    # Reporting Routes
    - kind: Rule
      match: Host(`api.university.ac.ke`) && PathPrefix(`/reports`)
      services:
        - name: reporting-service
          port: 8080
      middlewares:
        - name: auth-jwt
        - name: rate-limit
        - name: audit-log
