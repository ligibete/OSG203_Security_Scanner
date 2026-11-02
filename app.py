from flask import Flask, render_template, jsonify
import sqlite3
import subprocess
import os

app = Flask(__name__)
DB_NAME = "scanner.db"

def init_db():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS scan_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_time TEXT,
            module_name TEXT,
            risk_level TEXT,
            message TEXT
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/results', methods=['GET'])
def get_results():
    try:
        conn = sqlite3.connect(DB_NAME)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM scan_results ORDER BY id DESC")
        rows = cursor.fetchall()
        conn.close()
        
        data = [dict(row) for row in rows]
        return jsonify({"status": "success", "data": data})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/scan', methods=['POST'])
def trigger_scan():
    try:
        # Gọi Bash script quét hệ thống thực tế
        if os.path.exists("main.sh"):
            subprocess.run(["sudo", "bash", "main.sh"], check=False)
        else:
            # Fallback chèn dữ liệu mẫu nếu chưa có main.sh để test giao diện
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO scan_results (scan_time, module_name, risk_level, message) VALUES (datetime('now', 'localtime'), 'check_firewall', 'CRITICAL', 'Tường lửa UFW đang bị tắt. Trạng thái: Inactive.|sudo ufw enable')")
            cursor.execute("INSERT INTO scan_results (scan_time, module_name, risk_level, message) VALUES (datetime('now', 'localtime'), 'check_ssh', 'WARNING', 'Cấu hình SSH cho phép root login.|Sửa file /etc/ssh/sshd_config đổi thành PermitRootLogin no')")
            conn.commit()
            conn.close()

        return jsonify({"status": "success", "message": "Scan sequence completed successfully."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
