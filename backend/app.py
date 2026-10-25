import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import os
import glob
import subprocess
from flask import Flask, jsonify, request
from flask_cors import CORS
from database import get_db_connection, init_db
from log_parser import parse_scan_log

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MAIN_SCRIPT = os.path.join(BASE_DIR, "main.sh")
LOG_DIR = os.path.join(BASE_DIR, "logs")

# Khởi tạo bảng SQLite khi chạy app
init_db()

def sync_latest_log_to_db():
    """Task 4.3 & 4.6: Đọc file log mới nhất từ Bash Script và lưu vào SQLite"""
    log_files = glob.glob(os.path.join(LOG_DIR, "scan_*.log"))
    if not log_files:
        return 0, None

    latest_log = max(log_files, key=os.path.getmtime)
    findings = parse_scan_log(latest_log)

    conn = get_db_connection()
    cursor = conn.cursor()

    # Làm mới danh sách lỗi đang chờ duyệt (PENDING) để cập nhật kết quả quét mới nhất
    cursor.execute("DELETE FROM scan_results WHERE approval_status = 'PENDING'")

    for item in findings:
        cursor.execute("""
            INSERT INTO scan_results (
                rule_id, module_name, file_path, line_number,
                current_value, recommended_value, severity, status_scan,
                reason, fix_command, approval_status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
        """, (
            item["rule_id"],
            item["module_name"],
            item["file_path"],
            item["line_number"],
            item["current_value"],
            item["recommended_value"],
            item["severity"],
            item["status_scan"],
            item["reason"],
            item["fix_command"]
        ))

    cursor.execute("""
        INSERT INTO audit_logs (action, details)
        VALUES ('SCAN_COMPLETED', ?)
    """, (f"Đồng bộ {len(findings)} cảnh báo/lỗi từ file {os.path.basename(latest_log)} vào SQLite.",))

    conn.commit()
    conn.close()
    return len(findings), latest_log


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "OSG203 Security Scanner Backend"}), 200


@app.route("/api/scan", methods=["POST"])
def start_scan():
    """Task 4.4: API RESTful xử lý yêu cầu bắt đầu quét"""
    try:
        env = os.environ.copy()
        env["FLASK_RUN"] = "1"  # Tắt pop-up whiptail khi chạy qua API

        # Chạy sudo ./main.sh
        cmd = ["sudo", "-n", "bash", MAIN_SCRIPT] if os.geteuid() != 0 else ["bash", MAIN_SCRIPT]
        proc = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True, env=env, timeout=120)

        # Nếu sudo yêu cầu mật khẩu, vẫn đọc file log mới nhất hiện có trong thư mục logs/
        count, log_path = sync_latest_log_to_db()

        return jsonify({
            "status": "success",
            "message": "Đã thực thi quét bảo mật và lưu kết quả vào SQLite.",
            "log_file": os.path.basename(log_path) if log_path else None,
            "total_findings": count,
            "exit_code": proc.returncode
        }), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/api/results", methods=["GET"])
def list_results():
    """Task 4.5: API lấy danh sách kết quả quét và chi tiết rủi ro"""
    severity = request.args.get("severity")
    approval_status = request.args.get("approval_status")

    conn = get_db_connection()
    query = "SELECT * FROM scan_results WHERE 1=1"
    params = []

    if severity:
        query += " AND UPPER(severity) = UPPER(?)"
        params.append(severity)
    if approval_status:
        query += " AND UPPER(approval_status) = UPPER(?)"
        params.append(approval_status)

    query += " ORDER BY CASE severity WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END, id ASC"
    rows = conn.execute(query, params).fetchall()
    conn.close()

    return jsonify({
        "status": "success",
        "count": len(rows),
        "data": [dict(r) for r in rows]
    }), 200


@app.route("/api/results/<int:finding_id>", methods=["GET"])
def get_finding_detail(finding_id):
    """Task 4.5: Xem chi tiết 1 lỗi cụ thể (Diff View)"""
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM scan_results WHERE id = ?", (finding_id,)).fetchone()
    conn.close()
    if not row:
        return jsonify({"status": "error", "message": "Không tìm thấy lỗi này"}), 404
    return jsonify({"status": "success", "data": dict(row)}), 200


@app.route("/api/logs", methods=["GET"])
def list_audit_logs():
    """API lấy lịch sử thao tác (Audit log)"""
    conn = get_db_connection()
    rows = conn.execute("SELECT * FROM audit_logs ORDER BY id DESC LIMIT 100").fetchall()
    conn.close()
    return jsonify({
        "status": "success",
        "data": [dict(r) for r in rows]
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
