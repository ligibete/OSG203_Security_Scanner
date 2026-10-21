#!/usr/bin/env bash
# ==============================================================================
# scripts/check_ssh.sh - Module Kiểm tra Cấu hình Dịch vụ SSH Server
# Mã tiêu chí: SEC-SSH-01 đến SEC-SSH-05
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=../core/colors.sh
source "${PROJECT_ROOT}/core/colors.sh"
# shellcheck source=../core/logger.sh
source "${PROJECT_ROOT}/core/logger.sh"
# shellcheck source=../core/utils.sh
source "${PROJECT_ROOT}/core/utils.sh"

require_root

log_header "MODULE 2: KIỂM TRA BẢO MẬT DỊCH VỤ SSH SERVER"

SSHD_CONFIG="/etc/ssh/sshd_config"
if [[ ! -f "${SSHD_CONFIG}" ]]; then
    log_fail "Không tìm thấy tệp cấu hình SSH tại ${SSHD_CONFIG}. Có thể gói openssh-server chưa được cài đặt."
    exit 0
fi

# 1. Kiểm tra PermitRootLogin
log_info "[SEC-SSH-01] Kiểm tra chính sách đăng nhập root qua SSH (PermitRootLogin)..."
PERMIT_ROOT=$(grep -E '^\s*PermitRootLogin' "${SSHD_CONFIG}" /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | tail -n 1 || echo "prohibit-password")

if [[ "${PERMIT_ROOT}" == "no" ]]; then
    log_pass "PermitRootLogin được đặt là 'no' (Cấm hoàn toàn đăng nhập root qua SSH - Chuẩn CIS)."
elif [[ "${PERMIT_ROOT}" == "prohibit-password" ]] || [[ "${PERMIT_ROOT}" == "without-password" ]]; then
    log_warn "PermitRootLogin là '${PERMIT_ROOT}' (Chỉ cho phép đăng nhập qua SSH Key, khuyến nghị: 'no')."
else
    log_fail "PermitRootLogin được cấu hình là '${PERMIT_ROOT}' (Nguy cơ bị tấn công Brute-force mật khẩu root!)."
fi

# 2. Kiểm tra PermitEmptyPasswords
log_info "[SEC-SSH-02] Kiểm tra cho phép mật khẩu rỗng (PermitEmptyPasswords)..."
EMPTY_PASS=$(grep -E '^\s*PermitEmptyPasswords' "${SSHD_CONFIG}" /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | tail -n 1 || echo "no")

if [[ "${EMPTY_PASS}" == "no" ]]; then
    log_pass "PermitEmptyPasswords được đặt là 'no' (Đạt chuẩn)."
else
    log_fail "CẢNH BÁO: PermitEmptyPasswords là '${EMPTY_PASS}' (Cho phép đăng nhập không cần mật khẩu!)."
fi

# 3. Kiểm tra MaxAuthTries
log_info "[SEC-SSH-03] Kiểm tra số lần thử đăng nhập tối đa (MaxAuthTries)..."
MAX_AUTH=$(grep -E '^\s*MaxAuthTries' "${SSHD_CONFIG}" /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | tail -n 1 || echo "6")

if [[ "${MAX_AUTH}" -le 4 ]]; then
    log_pass "MaxAuthTries = ${MAX_AUTH} (Đạt chuẩn CIS: <= 4)."
else
    log_warn "MaxAuthTries = ${MAX_AUTH} (Khuyến nghị cấu hình giảm xuống 3 hoặc 4)."
fi

# 4. Kiểm tra Cổng SSH (Port)
log_info "[SEC-SSH-04] Rà soát cổng hoạt động của SSH..."
SSH_PORT=$(grep -E '^\s*Port' "${SSHD_CONFIG}" /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | tail -n 1 || echo "22")
if [[ "${SSH_PORT}" == "22" ]]; then
    log_info "SSH đang chạy trên cổng mặc định 22 (Có thể đổi sang cổng khác để giảm bớt quét rà tự động)."
else
    log_pass "SSH đang sử dụng cổng tùy chỉnh: ${SSH_PORT}"
fi

# 5. Kiểm tra X11Forwarding
log_info "[SEC-SSH-05] Kiểm tra chuyển tiếp giao diện đồ họa X11 (X11Forwarding)..."
X11_FWD=$(grep -E '^\s*X11Forwarding' "${SSHD_CONFIG}" /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | tail -n 1 || echo "no")
if [[ "${X11_FWD}" == "no" ]]; then
    log_pass "X11Forwarding được vô hiệu hóa (Đạt chuẩn máy chủ)."
else
    log_warn "X11Forwarding đang bật (${X11_FWD}). Khuyến nghị tắt nếu không dùng đồ họa qua SSH."
fi

echo -e "\n${BOLD}${BGREEN}Hoàn thành quét Module 2 (SSH Server).${NC}\n"
