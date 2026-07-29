/**
 * Universal Logout Script for all dashboards
 * Include this in any HTML file to add logout functionality
 */

// Logout function
function logout() {
    if (confirm('Are you sure you want to logout?')) {
        // Clear all session data
        localStorage.removeItem('access_token');
        localStorage.removeItem('user');
        localStorage.removeItem('token');
        localStorage.removeItem('session');
        
        // Clear any cookies
        document.cookie.split(";").forEach(function(c) {
            document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
        });
        
        // Redirect to login
        window.location.href = 'login_with_rbac.html';
    }
}

// Add logout button to page
function addLogoutButtonUniversal() {
    // Check if logout button already exists
    if (document.getElementById('universalLogoutBtn')) return;
    
    // Find header or create one
    let header = document.querySelector('.header, .header-right, nav, .navbar, .top-bar');
    
    if (!header) {
        // Create header if none exists
        header = document.createElement('div');
        header.style.cssText = `
            display: flex;
            justify-content: flex-end;
            padding: 16px 20px;
            background: rgba(15, 23, 42, 0.8);
            border-bottom: 1px solid rgba(255,255,255,0.06);
            position: sticky;
            top: 0;
            z-index: 1000;
        `;
        document.body.insertBefore(header, document.body.firstChild);
    }
    
    // Create logout button
    const btn = document.createElement('button');
    btn.id = 'universalLogoutBtn';
    btn.innerHTML = '🚪 Logout';
    btn.onclick = logout;
    btn.style.cssText = `
        background: rgba(239, 68, 68, 0.15);
        color: #f87171;
        border: 1px solid rgba(239, 68, 68, 0.2);
        padding: 8px 20px;
        border-radius: 8px;
        cursor: pointer;
        font-weight: 600;
        font-family: 'Inter', sans-serif;
        font-size: 14px;
        transition: all 0.2s;
        margin-left: auto;
    `;
    btn.onmouseover = function() {
        this.style.background = 'rgba(239, 68, 68, 0.25)';
    };
    btn.onmouseout = function() {
        this.style.background = 'rgba(239, 68, 68, 0.15)';
    };
    
    // Add user info before logout button
    const userInfo = document.createElement('span');
    userInfo.id = 'universalUserInfo';
    userInfo.style.cssText = `
        color: #94a3b8;
        font-size: 14px;
        margin-right: 16px;
    `;
    
    // Get user from localStorage
    try {
        const userData = localStorage.getItem('user');
        if (userData) {
            const user = JSON.parse(userData);
            userInfo.textContent = `👤 ${user.name || user.username}`;
        } else {
            userInfo.textContent = '👤 Guest';
        }
    } catch {
        userInfo.textContent = '👤 Guest';
    }
    
    header.appendChild(userInfo);
    header.appendChild(btn);
}

// Run on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addLogoutButtonUniversal);
} else {
    addLogoutButtonUniversal();
}
