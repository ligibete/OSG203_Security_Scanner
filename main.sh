#!/usr/bin/env bash
# ==============================================================================
# main.sh - Chương trình Chính Điều phối Bộ Dò quét Bảo mật OSG203
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nạp thư viện lõi
# shellcheck source=core/colors.sh
source "${SCRIPT_DIR}/core/colors.sh"
# shellcheck source=core/logger.sh
source "${SCRIPT_DIR}/core/logger.sh"
# shellcheck source=core/utils.sh
source "${SCRIPT_DIR}/core/utils.sh"

require_root

echo -e "${BOLD}${BBLUE}"
cat << "EOF"
================================================================================
   ____   _____  _____ ____    ___ _____    ____                                  
  / __ \ / ____|/ ____|___ \  / _ \___ /   / ___|  ___  ___ _   _ _ __ ___  ___ 
 | |  | | (___ | |  __  __) || | | ||_ \   \___ \ / _ \/ __| | | | '__/ _ \/ __|
 | |__| |\___ \| | |_ |/ __/ | |_| |__) |   ___) |  __/ (__| |_| | | |  __/\__ \
  \____/ |_____/ \____|_____(_)___/|____/   |____/ \___|\___|\__,_|_|  \___||___/
           AUTOMATED SERVER HARDENING & SECURITY SCANNER TOOL
================================================================================
EOF
echo -e "${NC}"

START_TIME=$(date +%s)
log_info "Khởi động tiến trình dò quét bảo mật toàn diện trên hệ thống..."
log_info "Hệ điều hành: $(get_os_info)"
log_info "Phần cứng: $(get_hardware_info)"
log_info "Thời gian bắt đầu: $(get_timestamp)"

# Danh sách các module kiểm tra
MODULES=(
    "check_users.sh"
    "check_ssh.sh"
    "check_firewall.sh"
    "check_permissions.sh"
)

for mod in "${MODULES[@]}"; do
    MOD_PATH="${SCRIPT_DIR}/scripts/${mod}"
    if [[ -x "${MOD_PATH}" ]]; then
        bash "${MOD_PATH}"
    else
        log_warn "Không tìm thấy hoặc chưa cấp quyền thực thi cho module: ${mod}"
    fi
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo -e "\n${BOLD}${BBLUE}================================================================================${NC}"
echo -e "${BOLD}${BGREEN}HOÀN THÀNH DÒ QUÉT TOÀN BỘ HỆ THỐNG TRONG ${ELAPSED} GIÂY!${NC}"
echo -e "Nhật ký quét chi tiết đã được lưu tại: ${BOLD}${SCAN_LOG_FILE}${NC}"
echo -e "${BOLD}${BBLUE}================================================================================${NC}\n"
