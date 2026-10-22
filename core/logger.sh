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

# Hàm log lỗi / vi phạm (FAIL)
log_fail() {
    local msg="$1"
    local ts
    ts="$(get_timestamp)"
    echo -e "${TAG_FAIL} ${msg}"
    echo "[${ts}] [FAIL] ${msg}" >> "${SCAN_LOG_FILE}"
}

# In tiêu đề phần mục
log_header() {
    local title="$1"
    echo -e "\n${BOLD}${BBLUE}=== [ ${title} ] ===${NC}"
    echo -e "=== [ ${title} ] ===" >> "${SCAN_LOG_FILE}"
}
