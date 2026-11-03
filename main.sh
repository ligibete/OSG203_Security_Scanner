#!/usr/bin/env bash
# ==============================================================================
# main.sh - Chương trình Chính Điều phối Bộ Dò quét Bảo mật OSG203
# ==============================================================================
#set -uo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nạp thư viện lõi
# shellcheck source=core/colors.sh
source "${BASE_DIR}/core/colors.sh"
# shellcheck source=core/logger.sh
source "${BASE_DIR}/core/logger.sh"
# shellcheck source=core/utils.sh
source "${BASE_DIR}/core/utils.sh"





# === KHỞI TẠO VÀ LÀM SẠCH DATABASE ===
DB="${BASE_DIR}/scanner.db"

# 1. Xóa thẳng tay file DB cũ bị hỏng để tránh hậu họa
rm -f "$DB"

# 2. Tạo mới file và đổ ngay cấu trúc bảng chuẩn vào
sqlite3 "$DB" "CREATE TABLE scan_results (id INTEGER PRIMARY KEY AUTOINCREMENT, scan_time TEXT, module_name TEXT, risk_level TEXT, message TEXT);"

# 3. Mở full quyền đọc/ghi để Docker và Script con không bị chặn
chmod 777 "$DB"




record_result() {
    local MODULE=$1
    local RISK=$2
    local MSG=$3
    
    # BƯỚC SỬA LỖI SQL: Xóa sạch hoặc thay thế dấu nháy đơn (') thành nháy kép (")
    local CLEAN_MSG="${MSG//\'/\"}"
    
    local DB_PATH="/home/project/OSG203_Security_Scanner/scanner.db"
    local TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Dùng CLEAN_MSG thay vì MSG để an toàn cho SQLite
    sqlite3 "$DB_PATH" "INSERT INTO scan_results (scan_time, module_name, risk_level, message) VALUES ('$TIME', '$MODULE', '$RISK', '$CLEAN_MSG');"
}

# BƯỚC SỬA LỖI COMMAND NOT FOUND: Export hàm này ra môi trường toàn cục
export -f record_result





# ... (các dòng source ở trên) ...

require_root "$@"

# ==========================================
# XỬ LÝ THAM SỐ DÒNG LỆNH (TASK 3.20)
# ==========================================
while getopts "hm:" flag; do
    case "${flag}" in
        h)
            echo "============================================="
            echo "    OSG203 SECURITY SCANNER - TRỢ GIÚP       "
            echo "============================================="
            echo "Sử dụng: sudo ./main.sh [tham số]"
            echo "Các tham số hỗ trợ:"
            echo "  -h      : Hiển thị bảng hướng dẫn này và thoát"
            echo "  -m <id> : Chỉ quét riêng một Module (Ví dụ: -m 1)"
            echo "============================================="
            exit 0
            ;;
        m)
            echo "Tính năng quét độc lập Module ${OPTARG} đang được kích hoạt..."
            # (Nhóm có thể bổ sung logic vào đây sau)
            exit 0
            ;;
        *)
            echo "[LỖI] Tham số không hợp lệ. Vui lòng dùng lệnh: sudo ./main.sh -h"
            exit 1
            ;;
    esac
done

# === ĐOẠN VẼ LOGO CŨ CỦA BẠN NẰM Ở DƯỚI NÀY ===
echo -e "${BOLD}${BBLUE}"
cat << "EOF"
# ... (phần logo ASCII) ...


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
    # Thay thế dòng MOD_PATH cũ bằng dòng khóa cứng này:
    MOD_PATH="/home/project/OSG203_Security_Scanner/scripts/${mod}"
    
    if [[ -f "${MOD_PATH}" ]]; then
        source "${MOD_PATH}"
    else
        log_warn "Không tìm thấy module: ${mod}"
    fi
done


# BẮT BUỘC: Đợi tất cả các tiến trình chạy ngầm kết thúc rồi mới tổng kết
wait

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo -e "\n${BOLD}${BBLUE}================================================================================${NC}"
echo -e "${BOLD}${BGREEN}HOÀN THÀNH DÒ QUÉT TOÀN BỘ HỆ THỐNG TRONG ${ELAPSED} GIÂY!${NC}"
echo -e "Nhật ký quét chi tiết đã được lưu tại: ${BOLD}${SCAN_LOG_FILE}${NC}"
echo -e "${BOLD}${BBLUE}================================================================================${NC}\n"





