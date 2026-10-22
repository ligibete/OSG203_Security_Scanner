#!/usr/bin/env bash
# ==============================================================================
# scripts/check_firewall.sh - Module Kiểm tra Tường lửa UFW & Dịch vụ Mạng
# Mã tiêu chí: SEC-NET-01 đến SEC-NET-05
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${BASE_DIR}/.." && pwd)"

# shellcheck source=../core/colors.sh
source "${PROJECT_ROOT}/core/colors.sh"
# shellcheck source=../core/logger.sh
source "${PROJECT_ROOT}/core/logger.sh"
# shellcheck source=../core/utils.sh
source "${PROJECT_ROOT}/core/utils.sh"

require_root

log_header "MODULE 3: KIỂM TRA TƯỜNG LỬA (UFW) VÀ DỊCH VỤ MẠNG"

# 1. Kiểm tra trạng thái tường lửa UFW
log_info "[SEC-NET-01] Kiểm tra trạng thái hoạt động của tường lửa UFW..."
if check_command ufw; then
    UFW_STATUS=$(ufw status 2>/dev/null | grep -i 'Status:' | awk '{print $2}' || echo "inactive")
    if [[ "${UFW_STATUS}" == "active" ]]; then
        log_pass "Tường lửa UFW đang ở trạng thái HOẠT ĐỘNG (active)."
    else
        log_fail "Tường lửa UFW đang TẮT (inactive). Máy chủ không được bảo vệ lọc gói tin!"
    fi
else
    log_fail "Gói công cụ ufw chưa được cài đặt trên hệ thống."
fi

# 2. Kiểm tra chính sách mặc định của UFW
log_info "[SEC-NET-02] Kiểm tra chính sách lưu lượng mặc định (Default Incoming Policy)..."
if check_command ufw; then
    DEFAULT_INCOMING=$(ufw status verbose 2>/dev/null | grep -i 'Default:' | grep -o 'deny (incoming)' || true)
    if [[ -n "${DEFAULT_INCOMING}" ]]; then
        log_pass "Chính sách lưu lượng đến mặc định là DENY (An toàn tuyệt đối)."
    else
        log_warn "Chính sách lưu lượng đến mặc định chưa cấu hình chặn toàn bộ."
    fi
fi

# 3. Rà soát các cổng đang mở lắng nghe (Listening Ports)
log_info "[SEC-NET-03] Rà soát các cổng TCP/UDP đang lắng nghe kết nối..."
if check_command ss; then
    OPEN_PORTS=$(ss -tuln 2>/dev/null | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -un | tr '\n' ' ' || echo "none")
    log_info "Các cổng mạng đang mở lắng nghe: ${OPEN_PORTS}"
    
    # Kiểm tra cổng không an toàn (telnet 23, ftp 21, rsh 514)
    for bad_port in 21 23 514; do
        if ss -tuln 2>/dev/null | grep -q ":${bad_port} "; then
            log_fail "CẢNH BÁO: Phát hiện cổng không an toàn đang mở (${bad_port})!"
        fi
    done
fi

# 4. Kiểm tra tính năng IP Forwarding
log_info "[SEC-NET-05] Kiểm tra tham số chuyển tiếp gói tin mạng (IP Forwarding)..."
IP_FWD=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "0")
if [[ "${IP_FWD}" == "0" ]]; then
    log_pass "net.ipv4.ip_forward = 0 (Chuyển tiếp IP bị vô hiệu hóa - Tránh bị dùng làm router trái phép)."
else
    log_warn "net.ipv4.ip_forward = 1 (Đang bật chuyển tiếp IP. Nếu không phải router/VPN server, khuyến nghị tắt)."
fi

echo -e "\n${BOLD}${BGREEN}Hoàn thành quét Module 3 (Firewall & Network).${NC}\n"
