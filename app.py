from flask import Flask, jsonify
import sqlite3
import subprocess

app = Flask(__name__)
DB_NAME = 'scanner.db'

# Mục 4.4: API RESTful xử lý yêu cầu bắt đầu quét
@app.route('/api/scan', methods=['POST'])
def run_scan():
    try:
        # Gọi script bash lõi quét chạy ngầm (Mục 4.3)
        subprocess.run(['bash', 'main.sh'], check=False)
        return jsonify({"status": "success", "message": "Tiến trình quét OSG203 đã hoàn tất!"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# Mục 4.5 & 4.6: Kết nối CSDL và API lấy danh sách kết quả
@app.route('/api/results', methods=['GET'])
def get_results():
    # Kết nối SQLite (Mục 4.6)
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM scan_results ORDER BY id DESC LIMIT 20")
    rows = cursor.fetchall()
    conn.close()

    results = []
    for row in rows:
        results.append({
            "id": row[0],
            "scan_time": row[1],
            "module_name": row[2],
            "risk_level": row[3],
            "message": row[4]
        })
    return jsonify({"status": "success", "data": results})

if __name__ == '__main__':
    # Chạy Web Server ở port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
