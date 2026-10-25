import os
import re

# Bộ từ điển ánh xạ chính xác các mã tiêu chí (SEC-SSH, SEC-USR, SEC-FIL, SEC-NET) của nhóm
RULE_METADATA = {
    # --- MODULE SSH (check_ssh.sh) ---
    "SEC-SSH-01": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*PermitRootLogin\b.*",
        "recommended_value": "PermitRootLogin no",
        "default_severity": "HIGH"
    },
    "SEC-SSH-02": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*PermitEmptyPasswords\b.*",
        "recommended_value": "PermitEmptyPasswords no",
        "default_severity": "HIGH"
    },
    "SEC-SSH-03": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*MaxAuthTries\b.*",
        "recommended_value": "MaxAuthTries 4",
        "default_severity": "MEDIUM"
    },
    "SEC-SSH-04": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*PasswordAuthentication\b.*",
        "recommended_value": "PasswordAuthentication no",
        "default_severity": "MEDIUM"
    },
    "SEC-SSH-05": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*Protocol\b.*",
        "recommended_value": "Protocol 2",
        "default_severity": "HIGH"
    },

    # --- MODULE USER & PAM (check_users.sh) ---
    "SEC-USR-01": {
        "file_path": "/etc/passwd",
        "search_regex": r"^[^:]+:[^:]*:0:",
        "recommended_value": "Chỉ duy nhất tài khoản root có UID = 0",
        "default_severity": "HIGH"
    },
    "SEC-USR-02": {
        "file_path": "/etc/login.defs",
        "search_regex": r"^\s*#?\s*PASS_MAX_DAYS\b.*",
        "recommended_value": "PASS_MAX_DAYS   90",
        "default_severity": "MEDIUM"
    },
    "SEC-USR-03": {
        "file_path": "/etc/login.defs",
        "search_regex": r"^\s*#?\s*PASS_MIN_DAYS\b.*",
        "recommended_value": "PASS_MIN_DAYS   7",
        "default_severity": "MEDIUM"
    },
    "SEC-USR-04": {
        "file_path": "/etc/pam.d/common-password",
        "search_regex": r"^\s*password\s+.*pam_unix\.so.*",
        "recommended_value": "password requisite pam_pwquality.so retry=3 minlen=8",
        "default_severity": "MEDIUM"
    },
    "SEC-USR-05": {
        "file_path": "/etc/sudoers",
        "search_regex": r"^\s*#?\s*%sudo\b.*|^\s*Defaults\b.*",
        "recommended_value": "Rà soát quyền sudo / NOPASSWD trong /etc/sudoers",
        "default_severity": "HIGH"
    },

    # --- MODULE FILE PERMISSIONS (check_permissions.sh) ---
    "SEC-FIL-01": {
        "file_path": "/etc/passwd",
        "search_regex": r"^root:.*",
        "recommended_value": "chmod 644 /etc/passwd && chown root:root /etc/passwd",
        "default_severity": "HIGH"
    },
    "SEC-FIL-02": {
        "file_path": "/etc/shadow",
        "search_regex": r".*",
        "recommended_value": "chmod 640 /etc/shadow && chown root:shadow /etc/shadow",
        "default_severity": "HIGH"
    },
    "SEC-FIL-03": {
        "file_path": "/etc/group",
        "search_regex": r"^root:.*",
        "recommended_value": "chmod 644 /etc/group && chown root:root /etc/group",
        "default_severity": "MEDIUM"
    },
    "SEC-FIL-04": {
        "file_path": "/etc/ssh/sshd_config",
        "search_regex": r"^\s*#?\s*PermitRootLogin\b.*",
        "recommended_value": "chmod 600 /etc/ssh/sshd_config",
        "default_severity": "MEDIUM"
    },
    "SEC-FIL-05": {
        "file_path": "/var/log",
        "search_regex": r".*",
        "recommended_value": "find / -xdev -type f -perm -0002 -exec chmod o-w {} +",
        "default_severity": "MEDIUM"
    },

    # --- MODULE NETWORK & FIREWALL (check_firewall.sh) ---
    "SEC-NET-01": {
        "file_path": "/etc/ufw/ufw.conf",
        "search_regex": r"^\s*#?\s*ENABLED=.*",
        "recommended_value": "ENABLED=yes",
        "default_severity": "HIGH"
    },
    "SEC-NET-02": {
        "file_path": "/etc/default/ufw",
        "search_regex": r"^\s*#?\s*DEFAULT_INPUT_POLICY=.*",
        "recommended_value": "DEFAULT_INPUT_POLICY=\"DROP\"",
        "default_severity": "MEDIUM"
    },
    "SEC-NET-03": {
        "file_path": "/etc/sysctl.conf",
        "search_regex": r"^\s*#?\s*net\.ipv4\.ip_forward\s*=.*",
        "recommended_value": "net.ipv4.ip_forward = 0",
        "default_severity": "MEDIUM"
    },
    "SEC-NET-04": {
        "file_path": "/etc/sysctl.conf",
        "search_regex": r"^\s*#?\s*net\.ipv4\.tcp_syncookies\s*=.*",
        "recommended_value": "net.ipv4.tcp_syncookies = 1",
        "default_severity": "MEDIUM"
    },
    "SEC-NET-05": {
        "file_path": "/etc/sysctl.conf",
        "search_regex": r"^\s*#?\s*net\.ipv4\.conf\.all\.accept_redirects\s*=.*",
        "recommended_value": "net.ipv4.conf.all.accept_redirects = 0",
        "default_severity": "MEDIUM"
    }
}

def locate_exact_line(file_path, search_regex, fallback_current=""):
    """Dò tìm chính xác số thứ tự dòng (line_number) và nội dung hiện tại trong file cấu hình"""
    if not os.path.exists(file_path) or os.path.isdir(file_path) or file_path in ("/etc/shadow", "/etc/sudoers"):
        return 1, fallback_current or "System Permission / Policy Check"

    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        # Ưu tiên 1: Tìm dòng cấu hình đang mở (không bị comment bằng #)
        for idx, line in enumerate(lines, start=1):
            stripped = line.strip()
            if not stripped.startswith("#") and re.match(search_regex, stripped):
                return idx, stripped

        # Ưu tiên 2: Nếu dòng đó đang bị comment (#), lấy đúng số dòng comment để sed sửa
        for idx, line in enumerate(lines, start=1):
            stripped = line.strip()
            if re.match(search_regex, stripped):
                return idx, stripped
    except Exception:
        pass

    return 1, fallback_current or "Default / Not explicitly set"

def parse_scan_log(log_file_path):
    """Task 4.3: Đọc file logs/scan_YYYYMMDD.log của Bash Script và chuyển thành danh sách Dict"""
    if not os.path.exists(log_file_path):
        return []

    findings = []
    current_module = "General Security"
    current_rule_id = "SEC-GEN-01"

    with open(log_file_path, "r", encoding="utf-8", errors="ignore") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line:
                continue

            # Bắt tiêu đề Module: === [ MODULE ... ] ===
            header_match = re.search(r"===\s*\[\s*(.*?)\s*\]\s*===", line)
            if header_match:
                current_module = header_match.group(1)
                continue

            # Bắt mã tiêu chí trong dòng [INFO]: [SEC-...]
            info_rule_match = re.search(r"\[(SEC-[A-Z0-9-]+)\]", line)
            if info_rule_match:
                current_rule_id = info_rule_match.group(1)

            # Bắt các dòng [FAIL] hoặc [WARN]
            status_match = re.search(r"\[(FAIL|WARN)\](?:\s*\[(HIGH|MEDIUM|LOW)\])?\s*(.*)", line)
            if status_match:
                status_scan = status_match.group(1)
                explicit_sev = status_match.group(2)
                message = status_match.group(3).strip()

                meta = RULE_METADATA.get(current_rule_id, {
                    "file_path": "/etc/sysctl.conf",
                    "search_regex": r".*",
                    "recommended_value": "Review security configuration",
                    "default_severity": "MEDIUM"
                })

                file_path = meta["file_path"]
                rec_val = meta["recommended_value"]
                severity = explicit_sev if explicit_sev else (
                    "MEDIUM" if status_scan == "WARN" else meta["default_severity"]
                )

                # Định vị chính xác số dòng lỗi trong file thật trên Ubuntu
                line_num, curr_val = locate_exact_line(file_path, meta["search_regex"])

                # Sinh câu lệnh khắc phục (sed cho file cấu hình, hoặc lệnh chmod/find)
                if any(cmd in rec_val for cmd in ("chmod ", "chown ", "find ", "Rà soát", "Chỉ duy nhất")):
                    fix_cmd = rec_val
                else:
                    safe_rec = rec_val.replace("/", "\\/")
                    fix_cmd = f"sed -i '{line_num}s/.*/{safe_rec}/' {file_path}"

                findings.append({
                    "rule_id": current_rule_id,
                    "module_name": current_module,
                    "file_path": file_path,
                    "line_number": line_num,
                    "current_value": curr_val,
                    "recommended_value": rec_val,
                    "severity": severity,
                    "status_scan": status_scan,
                    "reason": message,
                    "fix_command": fix_cmd
                })

    return findings
