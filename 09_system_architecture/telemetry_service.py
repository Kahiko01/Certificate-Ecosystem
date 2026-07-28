from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import uuid
import psycopg2
import json
from datetime import datetime, timedelta
import sys
import hashlib
import time

app = FastAPI(title="Telemetry & Monitoring Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Starting Telemetry Service...", file=sys.stderr, flush=True)

def get_db():
    try:
        conn = psycopg2.connect(
            host="certificate-postgres",
            database="certificate_ecosystem",
            user="cert_admin",
            password="secure_password_123",
            connect_timeout=5
        )
        return conn
    except Exception as e:
        print(f"DB Error: {e}", file=sys.stderr, flush=True)
        return None

# =============================================
# MODELS
# =============================================

class AuditLogCreate(BaseModel):
    user_id: Optional[str] = None
    username: Optional[str] = None
    action: str
    resource_type: str
    resource_id: Optional[str] = None
    details: Optional[Dict] = None
    status: str = "SUCCESS"
    error_message: Optional[str] = None
    response_time_ms: Optional[int] = None

class ClearanceAuditCreate(BaseModel):
    student_id: str
    department_code: str
    action: str
    performed_by: str
    performed_by_name: str
    previous_status: Optional[str] = None
    new_status: Optional[str] = None
    comments: Optional[str] = None

class CertificateAuditCreate(BaseModel):
    certificate_id: str
    action: str
    performed_by: str
    performed_by_name: str
    previous_state: Optional[Dict] = None
    new_state: Optional[Dict] = None

class SystemMetricCreate(BaseModel):
    metric_name: str
    metric_value: float
    metric_unit: Optional[str] = None
    tags: Optional[Dict] = None

# =============================================
# AUDIT LOGGING FUNCTIONS
# =============================================

def log_audit(audit_data: AuditLogCreate, ip_address: str = None, user_agent: str = None):
    """Log an audit entry"""
    try:
        conn = get_db()
        if not conn:
            return None
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO audit_logs (
                audit_id, user_id, username, action, resource_type, resource_id,
                details, ip_address, user_agent, status, error_message, response_time_ms
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            str(uuid.uuid4()),
            audit_data.user_id,
            audit_data.username,
            audit_data.action,
            audit_data.resource_type,
            audit_data.resource_id,
            json.dumps(audit_data.details) if audit_data.details else None,
            ip_address,
            user_agent,
            audit_data.status,
            audit_data.error_message,
            audit_data.response_time_ms
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        return True
    except Exception as e:
        print(f"Error logging audit: {e}", file=sys.stderr, flush=True)
        return False

def log_clearance_audit(data: ClearanceAuditCreate, ip_address: str = None):
    """Log clearance action"""
    try:
        conn = get_db()
        if not conn:
            return None
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO clearance_audit (
                clearance_audit_id, student_id, department_code, action,
                performed_by, performed_by_name, previous_status, new_status,
                comments, ip_address
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            str(uuid.uuid4()),
            data.student_id,
            data.department_code,
            data.action,
            data.performed_by,
            data.performed_by_name,
            data.previous_status,
            data.new_status,
            data.comments,
            ip_address
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        return True
    except Exception as e:
        print(f"Error logging clearance audit: {e}", file=sys.stderr, flush=True)
        return False

def log_certificate_audit(data: CertificateAuditCreate, ip_address: str = None):
    """Log certificate action"""
    try:
        conn = get_db()
        if not conn:
            return None
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO certificate_audit (
                certificate_audit_id, certificate_id, action,
                performed_by, performed_by_name, previous_state, new_state, ip_address
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            str(uuid.uuid4()),
            data.certificate_id,
            data.action,
            data.performed_by,
            data.performed_by_name,
            json.dumps(data.previous_state) if data.previous_state else None,
            json.dumps(data.new_state) if data.new_state else None,
            ip_address
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        return True
    except Exception as e:
        print(f"Error logging certificate audit: {e}", file=sys.stderr, flush=True)
        return False

# =============================================
# TELEMETRY API ENDPOINTS
# =============================================

@app.get("/")
async def root():
    return {"message": "Telemetry Service", "status": "running"}

@app.post("/telemetry/audit")
async def create_audit_log(audit: AuditLogCreate, request: Request):
    """Create an audit log entry"""
    ip = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    
    success = log_audit(audit, ip, user_agent)
    if success:
        return {"message": "Audit logged successfully"}
    raise HTTPException(status_code=500, detail="Failed to log audit")

@app.post("/telemetry/clearance")
async def create_clearance_audit(data: ClearanceAuditCreate, request: Request):
    """Log clearance audit"""
    ip = request.client.host if request.client else None
    success = log_clearance_audit(data, ip)
    if success:
        return {"message": "Clearance audit logged successfully"}
    raise HTTPException(status_code=500, detail="Failed to log clearance audit")

@app.post("/telemetry/certificate")
async def create_certificate_audit(data: CertificateAuditCreate, request: Request):
    """Log certificate audit"""
    ip = request.client.host if request.client else None
    success = log_certificate_audit(data, ip)
    if success:
        return {"message": "Certificate audit logged successfully"}
    raise HTTPException(status_code=500, detail="Failed to log certificate audit")

@app.post("/telemetry/metric")
async def create_system_metric(metric: SystemMetricCreate):
    """Log system metric"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO system_metrics (metric_id, metric_name, metric_value, metric_unit, tags)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            str(uuid.uuid4()),
            metric.metric_name,
            metric.metric_value,
            metric.metric_unit,
            json.dumps(metric.tags) if metric.tags else None
        ))
        
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Metric logged successfully"}
    except Exception as e:
        print(f"Error logging metric: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# QUERY ENDPOINTS (For Reporting)
# =============================================

@app.get("/telemetry/audit")
async def get_audit_logs(
    limit: int = 100,
    offset: int = 0,
    user_id: Optional[str] = None,
    action: Optional[str] = None,
    resource_type: Optional[str] = None,
    status: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
):
    """Get audit logs with filtering"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        query = """
            SELECT audit_id, user_id, username, action, resource_type, resource_id,
                   details, ip_address, user_agent, status, error_message, 
                   response_time_ms, created_at
            FROM audit_logs
            WHERE 1=1
        """
        params = []
        param_count = 1
        
        if user_id:
            query += f" AND user_id = ${param_count}"
            params.append(user_id)
            param_count += 1
        if action:
            query += f" AND action = ${param_count}"
            params.append(action)
            param_count += 1
        if resource_type:
            query += f" AND resource_type = ${param_count}"
            params.append(resource_type)
            param_count += 1
        if status:
            query += f" AND status = ${param_count}"
            params.append(status)
            param_count += 1
        if start_date:
            query += f" AND created_at >= ${param_count}::timestamp"
            params.append(start_date)
            param_count += 1
        if end_date:
            query += f" AND created_at <= ${param_count}::timestamp"
            params.append(end_date)
            param_count += 1
        
        query += f" ORDER BY created_at DESC LIMIT ${param_count} OFFSET ${param_count + 1}"
        params.append(limit)
        params.append(offset)
        
        cur = conn.cursor()
        cur.execute(query, params)
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        logs = []
        for row in results:
            logs.append({
                "audit_id": str(row[0]),
                "user_id": str(row[1]) if row[1] else None,
                "username": row[2],
                "action": row[3],
                "resource_type": row[4],
                "resource_id": str(row[5]) if row[5] else None,
                "details": row[6],
                "ip_address": str(row[7]) if row[7] else None,
                "user_agent": row[8],
                "status": row[9],
                "error_message": row[10],
                "response_time_ms": row[11],
                "created_at": row[12].isoformat() if row[12] else None
            })
        
        return {"logs": logs, "count": len(logs)}
        
    except Exception as e:
        print(f"Error getting audit logs: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/telemetry/clearance/{student_id}")
async def get_student_clearance_history(student_id: str):
    """Get clearance history for a student"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                ca.clearance_audit_id,
                ca.department_code,
                ca.action,
                ca.performed_by_name,
                ca.previous_status,
                ca.new_status,
                ca.comments,
                ca.ip_address,
                ca.created_at
            FROM clearance_audit ca
            WHERE ca.student_id = %s
            ORDER BY ca.created_at DESC
        """, (student_id,))
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        history = []
        for row in results:
            history.append({
                "id": str(row[0]),
                "department": row[1],
                "action": row[2],
                "performed_by": row[3],
                "previous_status": row[4],
                "new_status": row[5],
                "comments": row[6],
                "ip_address": str(row[7]) if row[7] else None,
                "created_at": row[8].isoformat() if row[8] else None
            })
        
        return {"student_id": student_id, "history": history, "count": len(history)}
        
    except Exception as e:
        print(f"Error getting clearance history: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/telemetry/certificate/{certificate_id}")
async def get_certificate_audit_trail(certificate_id: str):
    """Get certificate audit trail"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                ca.certificate_audit_id,
                ca.action,
                ca.performed_by_name,
                ca.previous_state,
                ca.new_state,
                ca.ip_address,
                ca.created_at
            FROM certificate_audit ca
            WHERE ca.certificate_id = %s
            ORDER BY ca.created_at
        """, (certificate_id,))
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        trail = []
        for row in results:
            trail.append({
                "id": str(row[0]),
                "action": row[1],
                "performed_by": row[2],
                "previous_state": row[3],
                "new_state": row[4],
                "ip_address": str(row[5]) if row[5] else None,
                "created_at": row[6].isoformat() if row[6] else None
            })
        
        return {"certificate_id": certificate_id, "audit_trail": trail, "count": len(trail)}
        
    except Exception as e:
        print(f"Error getting certificate audit: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/telemetry/stats")
async def get_telemetry_stats():
    """Get telemetry statistics"""
    try:
        conn = get_db()
        if not conn:
            raise HTTPException(status_code=503, detail="Database unavailable")
        
        cur = conn.cursor()
        
        # Total audit logs
        cur.execute("SELECT COUNT(*) FROM audit_logs")
        total_audit_logs = cur.fetchone()[0]
        
        # Actions by type
        cur.execute("""
            SELECT action, COUNT(*) 
            FROM audit_logs 
            GROUP BY action 
            ORDER BY COUNT(*) DESC 
            LIMIT 10
        """)
        top_actions = cur.fetchall()
        
        # Users with most actions
        cur.execute("""
            SELECT username, COUNT(*) as action_count
            FROM audit_logs
            WHERE username IS NOT NULL
            GROUP BY username
            ORDER BY action_count DESC
            LIMIT 10
        """)
        top_users = cur.fetchall()
        
        # Today's activity
        cur.execute("""
            SELECT COUNT(*) 
            FROM audit_logs 
            WHERE DATE(created_at) = CURRENT_DATE
        """)
        today_activity = cur.fetchone()[0]
        
        # Clearance statistics
        cur.execute("""
            SELECT department_code, COUNT(*) as total,
                   COUNT(CASE WHEN action = 'CLEARED' THEN 1 END) as cleared,
                   COUNT(CASE WHEN action = 'REJECTED' THEN 1 END) as rejected
            FROM clearance_audit
            GROUP BY department_code
        """)
        clearance_stats = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return {
            "total_audit_logs": total_audit_logs,
            "today_activity": today_activity,
            "top_actions": [{"action": a[0], "count": a[1]} for a in top_actions],
            "top_users": [{"username": u[0], "actions": u[1]} for u in top_users],
            "clearance_stats": [
                {
                    "department": cs[0],
                    "total": cs[1],
                    "cleared": cs[2],
                    "rejected": cs[3]
                }
                for cs in clearance_stats
            ],
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Error getting telemetry stats: {e}", file=sys.stderr, flush=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    print("Starting Telemetry Service...", file=sys.stderr, flush=True)
    uvicorn.run(app, host="0.0.0.0", port=8002)
