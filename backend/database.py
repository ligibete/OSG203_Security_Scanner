import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "osg203_scanner.db")

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Task 4.1: Thiết kế cấu trúc bảng SQLite lưu kết quả quét và lịch sử thao tác"""
    conn = get_db_connection()
    cursor = conn.cursor()

    # Bảng 1: Lưu kết quả quét chi tiết (Phục vụ Admin Review & Zero Auto-Fix)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS scan_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rule_id TEXT NOT NULL,
            module_name TEXT,
            file_path TEXT NOT NULL,
            line_number INTEGER DEFAULT 1,
            current_value TEXT,
            recommended_value TEXT,
            severity TEXT DEFAULT 'HIGH',
            status_scan TEXT DEFAULT 'FAIL',
            reason TEXT,
            fix_command TEXT,
            approval_status TEXT DEFAULT 'PENDING' CHECK(approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'APPLIED', 'ROLLED_BACK')),
            scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Bảng 2: Lưu lịch sử thao tác (Audit Log)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            finding_id INTEGER,
            action TEXT NOT NULL,
            performed_by TEXT DEFAULT 'Admin',
            details TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (finding_id) REFERENCES scan_results (id)
        )
    """)

    conn.commit()
    conn.close()
    print(f"[+] Đã khởi tạo CSDL SQLite thành công tại: {DB_PATH}")

if __name__ == "__main__":
    init_db()
