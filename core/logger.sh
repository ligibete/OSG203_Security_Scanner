#!/usr/bin/env bash
# ==============================================================================
# core/logger.sh - Thư viện ghi log chuẩn hóa cho OSG203 Security Scanner
# ==============================================================================

# Khởi tạo thư mục logs nếu chưa tồn tại
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
mkdir -p "${LOG_DIR}"

CURRENT_DATE="$(date +'%Y%m%d')"
SCAN_LOG_FILE="${LOG_DIR}/scan_${CURRENT_DATE}.log"

# Hàm lấy timestamp
get_timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

# Hàm log thông tin chung
log_info() {
    local msg="$1"
    local ts
    ts="$(get_timestamp)"
    echo -e "${TAG_INFO} ${msg}"
    echo "[${ts}] [INFO] ${msg}" >> "${SCAN_LOG_FILE}"
}

# Hàm log đạt chuẩn (PASS)
log_pass() {
    local msg="$1"
    local ts
    ts="$(get_timestamp)"
    echo -e "${TAG_PASS} ${msg}"
    echo "[${ts}] [PASS] ${msg}" >> "${SCAN_LOG_FILE}"
}

# Hàm log cảnh báo (WARN)
log_warn() {
    local msg="$1"
    local ts
    ts="$(get_timestamp)"
    echo -e "${TAG_WARN} ${msg}"
    echo "[${ts}] [WARN] ${msg}" >> "${SCAN_LOG_FILE}"
}

# Hàm log lỗi / vi phạm (FAIL) - Bổ sung gán nhãn rủi ro (Task 3.22)
log_fail() {
    local msg="$1"
    local risk_level="${2:-}" # Bắt tham số thứ 2 (HIGH/MEDIUM/LOW)
    local ts
    ts="$(get_timestamp)"
    
    if [[ "$risk_level" == "HIGH" ]]; then
        echo -e "${BRED}[FAIL] [RỦI RO: HIGH] ${msg}${NC}"
        echo "[${ts}] [FAIL] [HIGH] ${msg}" >> "${SCAN_LOG_FILE}"
    elif [[ "$risk_level" == "MEDIUM" ]]; then
        echo -e "${BYELLOW}[FAIL] [RỦI RO: MEDIUM] ${msg}${NC}"
        echo "[${ts}] [FAIL] [MEDIUM] ${msg}" >> "${SCAN_LOG_FILE}"
    elif [[ "$risk_level" == "LOW" ]]; then
        echo -e "${BCYAN}[FAIL] [RỦI RO: LOW] ${msg}${NC}"
        echo "[${ts}] [FAIL] [LOW] ${msg}" >> "${SCAN_LOG_FILE}"
    else
        # Nếu không truyền mức độ, dùng mặc định
        echo -e "${TAG_FAIL} ${msg}"
        echo "[${ts}] [FAIL] ${msg}" >> "${SCAN_LOG_FILE}"
    fi
}

# In tiêu đề phần mục
log_header() {
    local title="$1"
    echo -e "\n${BOLD}${BBLUE}=== [ ${title} ] ===${NC}"
    echo -e "=== [ ${title} ] ===" >> "${SCAN_LOG_FILE}"
}
