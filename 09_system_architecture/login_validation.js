/**
 * Department Login Validation
 * Prevents departments from accessing other department dashboards
 */

// Role to allowed dashboards mapping
const roleDashboardAccess = {
    'SYSTEM_ADMIN': ['*'],
    'REGISTRAR': ['registry_dashboard.html', 'unified_dashboard.html', 'dashboard_hub.html'],
    'FINANCE_HEAD': ['finance_dashboard.html', 'unified_dashboard.html', 'dashboard_hub.html'],
    'FINANCE_OFFICER': ['finance_dashboard.html', 'dashboard_hub.html'],
    'ACADEMIC_HEAD': ['academic_dashboard.html', 'registry_dashboard.html', 'dashboard_hub.html'],
    'ACADEMIC_OFFICER': ['academic_dashboard.html', 'dashboard_hub.html'],
    'LIBRARY_HEAD': ['dashboard_hub.html'],
    'LIBRARY_OFFICER': ['dashboard_hub.html'],
    'ACCOMMODATION_HEAD': ['dashboard_hub.html'],
    'ACCOMMODATION_OFFICER': ['dashboard_hub.html'],
    'DISCIPLINE_HEAD': ['dashboard_hub.html'],
    'DISCIPLINE_OFFICER': ['dashboard_hub.html'],
    'REGISTRY_HEAD': ['registry_dashboard.html', 'dashboard_hub.html'],
    'REGISTRY_OFFICER': ['registry_dashboard.html', 'dashboard_hub.html'],
    'SENATE_HEAD': ['dashboard_hub.html'],
    'SENATE_OFFICER': ['dashboard_hub.html'],
    'DEAN': ['deans_dashboard.html', 'academic_dashboard.html', 'dashboard_hub.html'],
    'STUDENT': ['student_dashboard.html', 'dashboard_hub.html'],
    'AUDITOR': ['monitoring_dashboard.html', 'service_status.html', 'dashboard_hub.html']
};

function getCurrentPage() {
    const path = window.location.pathname;
    return path.split('/').pop();
}

function validateDepartmentAccess() {
    const user = getUser();
    if (!user) return false;
    
    const role = user.role;
    const currentPage = getCurrentPage();
    
    // If no current page or it's the login page, allow
    if (!currentPage || currentPage === 'login_with_rbac.html' || currentPage === 'role_redirect.html') {
        return true;
    }
    
    // Check if role has access to this page
    const allowedPages = roleDashboardAccess[role] || ['dashboard_hub.html'];
    
    // If allowed pages includes '*', allow all
    if (allowedPages.includes('*')) return true;
    
    // Check if current page is allowed
    const isAllowed = allowedPages.some(page => currentPage.includes(page) || currentPage === page);
    
    if (!isAllowed) {
        // Redirect to dashboard hub
        window.location.href = 'dashboard_hub.html';
        return false;
    }
    
    return true;
}

// Run validation on page load
function validateAccess() {
    const token = localStorage.getItem('access_token');
    if (!token) {
        // Not logged in, allow access to public pages
        const publicPages = ['login_with_rbac.html', 'verify_portal.html', 'login_reference.html'];
        const currentPage = getCurrentPage();
        if (!publicPages.includes(currentPage)) {
            window.location.href = 'login_with_rbac.html';
        }
        return;
    }
    
    validateDepartmentAccess();
}

// Run on load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', validateAccess);
} else {
    validateAccess();
}
