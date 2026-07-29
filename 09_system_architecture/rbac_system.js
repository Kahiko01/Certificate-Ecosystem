/**
 * Role-Based Access Control (RBAC) System
 * Defines permissions for each role in the Certificate Ecosystem
 */

const RBAC = {
    // Define all roles and their permissions
    roles: {
        // System Administrator - Full access to everything
        SYSTEM_ADMIN: {
            permissions: ['*'],
            dashboards: ['all'],
            actions: ['*'],
            clearance: ['all'],
            students: ['all'],
            certificates: ['all'],
            finance: ['all'],
            academic: ['all'],
            registry: ['all'],
            deans: ['all']
        },

        // Registrar - Academic records and certificates
        REGISTRAR: {
            permissions: ['view_students', 'manage_certificates', 'view_clearance', 'manage_graduation'],
            dashboards: ['academic', 'registry', 'clearance'],
            actions: ['view', 'create_certificate', 'verify_certificate'],
            clearance: ['view', 'approve'],
            students: ['view', 'update'],
            certificates: ['create', 'view', 'verify']
        },

        // Finance Head - Financial management
        FINANCE_HEAD: {
            permissions: ['view_students', 'manage_finance', 'view_clearance'],
            dashboards: ['finance'],
            actions: ['view', 'update_finance', 'clear_finance'],
            clearance: ['view', 'approve_finance'],
            students: ['view'],
            finance: ['view', 'update', 'clear']
        },

        // Finance Officer - Basic financial operations
        FINANCE_OFFICER: {
            permissions: ['view_students', 'view_finance', 'update_finance'],
            dashboards: ['finance'],
            actions: ['view', 'update_finance'],
            clearance: ['view'],
            students: ['view'],
            finance: ['view', 'update']
        },

        // Academic Head - Academic management
        ACADEMIC_HEAD: {
            permissions: ['view_students', 'manage_academic', 'view_clearance'],
            dashboards: ['academic', 'registry'],
            actions: ['view', 'update_academic', 'approve_academic'],
            clearance: ['view', 'approve_academic'],
            students: ['view', 'update'],
            academic: ['view', 'update', 'approve']
        },

        // Academic Officer - Basic academic operations
        ACADEMIC_OFFICER: {
            permissions: ['view_students', 'view_academic', 'update_academic'],
            dashboards: ['academic'],
            actions: ['view', 'update_academic'],
            clearance: ['view'],
            students: ['view'],
            academic: ['view', 'update']
        },

        // Library Head - Library management
        LIBRARY_HEAD: {
            permissions: ['view_students', 'manage_library', 'view_clearance'],
            dashboards: ['clearance'],
            actions: ['view', 'clear_library'],
            clearance: ['view', 'approve_library'],
            students: ['view']
        },

        // Library Officer - Basic library operations
        LIBRARY_OFFICER: {
            permissions: ['view_students', 'view_library', 'update_library'],
            dashboards: ['clearance'],
            actions: ['view', 'update_library'],
            clearance: ['view'],
            students: ['view']
        },

        // Accommodation Head - Accommodation management
        ACCOMMODATION_HEAD: {
            permissions: ['view_students', 'manage_accommodation', 'view_clearance'],
            dashboards: ['clearance'],
            actions: ['view', 'clear_accommodation'],
            clearance: ['view', 'approve_accommodation'],
            students: ['view']
        },

        // Accommodation Officer - Basic accommodation operations
        ACCOMMODATION_OFFICER: {
            permissions: ['view_students', 'view_accommodation', 'update_accommodation'],
            dashboards: ['clearance'],
            actions: ['view', 'update_accommodation'],
            clearance: ['view'],
            students: ['view']
        },

        // Discipline Head - Discipline management
        DISCIPLINE_HEAD: {
            permissions: ['view_students', 'manage_discipline', 'view_clearance'],
            dashboards: ['clearance'],
            actions: ['view', 'clear_discipline'],
            clearance: ['view', 'approve_discipline'],
            students: ['view']
        },

        // Discipline Officer - Basic discipline operations
        DISCIPLINE_OFFICER: {
            permissions: ['view_students', 'view_discipline', 'update_discipline'],
            dashboards: ['clearance'],
            actions: ['view', 'update_discipline'],
            clearance: ['view'],
            students: ['view']
        },

        // Registry Head - Registry management
        REGISTRY_HEAD: {
            permissions: ['view_students', 'manage_registry', 'view_clearance', 'manage_certificates'],
            dashboards: ['registry', 'certificates'],
            actions: ['view', 'clear_registry', 'approve_registry', 'create_certificate'],
            clearance: ['view', 'approve_registry'],
            students: ['view', 'update'],
            certificates: ['create', 'view', 'verify']
        },

        // Registry Officer - Basic registry operations
        REGISTRY_OFFICER: {
            permissions: ['view_students', 'view_registry', 'update_registry'],
            dashboards: ['registry'],
            actions: ['view', 'update_registry'],
            clearance: ['view'],
            students: ['view']
        },

        // Senate Head - Senate approvals
        SENATE_HEAD: {
            permissions: ['view_students', 'manage_senate', 'view_clearance'],
            dashboards: ['registry'],
            actions: ['view', 'approve_senate'],
            clearance: ['view', 'approve_senate'],
            students: ['view']
        },

        // Senate Officer - Basic senate operations
        SENATE_OFFICER: {
            permissions: ['view_students', 'view_senate'],
            dashboards: ['registry'],
            actions: ['view'],
            clearance: ['view'],
            students: ['view']
        },

        // Dean - Department overview
        DEAN: {
            permissions: ['view_students', 'view_faculty', 'view_department', 'view_clearance'],
            dashboards: ['deans'],
            actions: ['view', 'approve_department'],
            clearance: ['view'],
            students: ['view'],
            faculty: ['view']
        },

        // Student - View own records
        STUDENT: {
            permissions: ['view_own_records', 'view_own_certificates', 'view_own_clearance'],
            dashboards: ['student'],
            actions: ['view', 'verify_own_certificate'],
            clearance: ['view_own'],
            students: ['view_own'],
            certificates: ['view_own', 'verify_own']
        },

        // Public Verifier - Certificate verification
        PUBLIC_VERIFIER: {
            permissions: ['verify_certificates'],
            dashboards: ['verify'],
            actions: ['verify_certificate'],
            certificates: ['verify']
        }
    },

    // Define what each role can see in the dashboard
    dashboardAccess: {
        'SYSTEM_ADMIN': ['master', 'finance', 'registry', 'academic', 'deans', 'clearance', 'users', 'audit', 'admin'],
        'REGISTRAR': ['master', 'registry', 'certificates', 'clearance'],
        'FINANCE_HEAD': ['master', 'finance'],
        'FINANCE_OFFICER': ['finance'],
        'ACADEMIC_HEAD': ['master', 'academic', 'registry'],
        'ACADEMIC_OFFICER': ['academic'],
        'LIBRARY_HEAD': ['master', 'clearance'],
        'LIBRARY_OFFICER': ['clearance'],
        'ACCOMMODATION_HEAD': ['master', 'clearance'],
        'ACCOMMODATION_OFFICER': ['clearance'],
        'DISCIPLINE_HEAD': ['master', 'clearance'],
        'DISCIPLINE_OFFICER': ['clearance'],
        'REGISTRY_HEAD': ['master', 'registry', 'certificates'],
        'REGISTRY_OFFICER': ['registry'],
        'SENATE_HEAD': ['master', 'registry'],
        'SENATE_OFFICER': ['registry'],
        'DEAN': ['master', 'deans'],
        'STUDENT': ['student'],
        'PUBLIC_VERIFIER': ['verify']
    },

    // Check if user has permission
    hasPermission(userRole, permission) {
        if (!userRole || !this.roles[userRole]) return false;
        const role = this.roles[userRole];
        if (role.permissions.includes('*')) return true;
        return role.permissions.includes(permission);
    },

    // Check if user can access a dashboard
    canAccessDashboard(userRole, dashboard) {
        if (!userRole || !this.dashboardAccess[userRole]) return false;
        const access = this.dashboardAccess[userRole];
        if (access.includes('all')) return true;
        return access.includes(dashboard);
    },

    // Get visible dashboards for a user
    getVisibleDashboards(userRole) {
        if (!userRole || !this.dashboardAccess[userRole]) return [];
        return this.dashboardAccess[userRole];
    },

    // Check if user can perform an action
    canPerformAction(userRole, action, resource) {
        if (!userRole || !this.roles[userRole]) return false;
        const role = this.roles[userRole];
        if (role.permissions.includes('*')) return true;
        if (role.actions && role.actions.includes('*')) return true;
        if (role.actions && role.actions.includes(action)) return true;
        if (role[resource] && role[resource].includes('all')) return true;
        if (role[resource] && role[resource].includes(action)) return true;
        return false;
    },

    // Get all roles
    getAllRoles() {
        return Object.keys(this.roles);
    },

    // Get role display name
    getRoleDisplayName(role) {
        const displayNames = {
            'SYSTEM_ADMIN': 'System Administrator',
            'REGISTRAR': 'Registrar',
            'FINANCE_HEAD': 'Finance Head',
            'FINANCE_OFFICER': 'Finance Officer',
            'ACADEMIC_HEAD': 'Academic Head',
            'ACADEMIC_OFFICER': 'Academic Officer',
            'LIBRARY_HEAD': 'Library Head',
            'LIBRARY_OFFICER': 'Library Officer',
            'ACCOMMODATION_HEAD': 'Accommodation Head',
            'ACCOMMODATION_OFFICER': 'Accommodation Officer',
            'DISCIPLINE_HEAD': 'Discipline Head',
            'DISCIPLINE_OFFICER': 'Discipline Officer',
            'REGISTRY_HEAD': 'Registry Head',
            'REGISTRY_OFFICER': 'Registry Officer',
            'SENATE_HEAD': 'Senate Head',
            'SENATE_OFFICER': 'Senate Officer',
            'DEAN': 'Dean',
            'STUDENT': 'Student',
            'PUBLIC_VERIFIER': 'Public Verifier'
        };
        return displayNames[role] || role;
    },

    // Get role icon
    getRoleIcon(role) {
        const icons = {
            'SYSTEM_ADMIN': '⚙️',
            'REGISTRAR': '📋',
            'FINANCE_HEAD': '💰',
            'FINANCE_OFFICER': '💳',
            'ACADEMIC_HEAD': '📚',
            'ACADEMIC_OFFICER': '📖',
            'LIBRARY_HEAD': '📕',
            'LIBRARY_OFFICER': '📗',
            'ACCOMMODATION_HEAD': '🏠',
            'ACCOMMODATION_OFFICER': '🛏️',
            'DISCIPLINE_HEAD': '⚖️',
            'DISCIPLINE_OFFICER': '📋',
            'REGISTRY_HEAD': '📋',
            'REGISTRY_OFFICER': '📄',
            'SENATE_HEAD': '🏛️',
            'SENATE_OFFICER': '📜',
            'DEAN': '🏫',
            'STUDENT': '👨‍🎓',
            'PUBLIC_VERIFIER': '🔍'
        };
        return icons[role] || '👤';
    },

    // Get role description
    getRoleDescription(role) {
        const descriptions = {
            'SYSTEM_ADMIN': 'Full system access and administration',
            'REGISTRAR': 'Manage academic records and certificates',
            'FINANCE_HEAD': 'Oversee financial operations and clearance',
            'FINANCE_OFFICER': 'Process financial transactions',
            'ACADEMIC_HEAD': 'Manage academic programs and students',
            'ACADEMIC_OFFICER': 'Process academic records',
            'LIBRARY_HEAD': 'Oversee library services and clearance',
            'LIBRARY_OFFICER': 'Manage library operations',
            'ACCOMMODATION_HEAD': 'Oversee accommodation services',
            'ACCOMMODATION_OFFICER': 'Manage accommodation operations',
            'DISCIPLINE_HEAD': 'Oversee disciplinary matters',
            'DISCIPLINE_OFFICER': 'Process disciplinary cases',
            'REGISTRY_HEAD': 'Oversee registry operations',
            'REGISTRY_OFFICER': 'Process registry documents',
            'SENATE_HEAD': 'Oversee senate approvals',
            'SENATE_OFFICER': 'Process senate approvals',
            'DEAN': 'Oversee department operations',
            'STUDENT': 'View own academic records',
            'PUBLIC_VERIFIER': 'Verify certificate authenticity'
        };
        return descriptions[role] || 'No description available';
    }
};

// Export for use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RBAC;
}
