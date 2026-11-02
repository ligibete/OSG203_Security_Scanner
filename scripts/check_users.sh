#!/usr/bin/env bash
# ==============================================================================
# scripts/check_users.sh - Module Kiểm tra Quản lý Người dùng & Xác thực
# Mã tiêu chí: SEC-USR-01 đến SEC-USR-05
# ==============================================================================
set -eo pipefail
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

log_header "MODULE 1: KIỂM TRA TÀI KHOẢN VÀ XÁC THỰC NGƯỜI DÙNG"

# 1. Kiểm tra tài khoản có UID 0 ngoài root
if [[ -z "${UID_ZERO_ACCOUNTS}" ]]; then
    log_pass "Chỉ có duy nhất người dùng 'root' có UID = 0."
    record_result "check_users" "SECURE" "Chỉ có duy nhất người dùng root có UID 0.|Không yêu cầu hành động."
else
    log_fail "Phát hiện tài khoản bất thường có UID = 0: ${UID_ZERO_ACCOUNTS}"
    record_result "check_users" "CRITICAL" "Phát hiện tài khoản rác có đặc quyền Root trái phép!|sudo passwd -l ${UID_ZERO_ACCOUNTS} && sudo usermod -s /usr/sbin/nologin ${UID_ZERO_ACCOUNTS}"
fi

# 2. Kiểm tra tài khoản không có mật khẩu (Empty Password)
if [[ -z "${BLANK_HASH}" ]]; then
    log_pass "Không có tài khoản nào có mật khẩu để trống."
    record_result "check_users" "SECURE" "Không có tài khoản nào rỗng mật khẩu.|Không yêu cầu hành động."
else
    log_fail "CẢNH BÁO NGUY HIỂM: Tài khoản không có mật khẩu: ${BLANK_HASH}"
    record_result "check_users" "CRITICAL" "Phát hiện tài khoản không có mật khẩu: ${BLANK_HASH}|sudo passwd -l ${BLANK_HASH}"
fi

# 3. Kiểm tra chính sách mật khẩu trong /etc/login.defs
log_info "[SEC-USR-03] Kiểm tra chính sách thời hạn mật khẩu trong /etc/login.defs..."
PASS_MAX_DAYS=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "99999")
PASS_MIN_DAYS=$(grep -E '^PASS_MIN_DAYS' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "0")
PASS_WARN_AGE=$(grep -E '^PASS_WARN_AGE' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "7")

if [[ "${PASS_MAX_DAYS}" -le 90 ]]; then
    log_pass "Thời hạn mật khẩu tối đa (PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày) đạt chuẩn CIS Benchmark."
    record_result "check_password_policy" "SECURE" "Thời hạn mật khẩu tối đa (PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày) đạt chuẩn." "Hệ thống an toàn"
else
    log_warn "PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày (Khuyến nghị: <= 90 ngày)."
    record_result "check_password_policy" "WARNING" "PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày (Khuyến nghị: <= 90 ngày)." "Sửa file /etc/login.defs đặt PASS_MAX_DAYS thành 90"
fi

# 4. Kiểm tra phân quyền tệp tin sudoers và cờ NOPASSWD
log_info "[SEC-USR-04] Rà soát cấu hình đặc quyền sudoers..."
if [[ -f /etc/sudoers ]]; then
    # Viết liền không có khoảng trắng ở 2 bên dấu =
    SUDOERS_PERM=$(stat -c "%a" /etc/sudoers)
    
    # Kiểm tra cả 2 trường hợp: 440 hoặc 0440
    if [[ "${SUDOERS_PERM}" == "440" ]] || [[ "${SUDOERS_PERM}" == "400" ]] || [[ "${SUDOERS_PERM}" == "0440" ]]; then
        log_pass "Phân quyền /etc/sudoers an toàn: ${SUDOERS_PERM}"
        record_result "check_users" "SECURE" "Phân quyền /etc/sudoers an toàn (${SUDOERS_PERM}).|Không yêu cầu hành động."
    else
        log_fail "Phân quyền /etc/sudoers không an toàn: ${SUDOERS_PERM} (Yêu cầu 440 hoặc 400)"
        record_result "check_users" "CRITICAL" "Phân quyền /etc/sudoers không an toàn (${SUDOERS_PERM})!|sudo chmod 440 /etc/sudoers"
    fi
fi

# 5. Kiểm tra quyền shell đăng nhập bất thường
if [[ -z "${SYSTEM_USERS_WITH_SHELL}" ]]; then
    log_pass "Tất cả các tài khoản dịch vụ hệ thống đều được khóa shell..."
    record_result "check_users" "SECURE" "Các tài khoản hệ thống đã được khóa shell an toàn.|Không yêu cầu hành động."
else
    log_warn "Tài khoản hệ thống có shell đăng nhập mở: ${SYSTEM_USERS_WITH_SHELL}"
    record_result "check_users" "WARNING" "Tài khoản dịch vụ có shell đăng nhập mở: ${SYSTEM_USERS_WITH_SHELL}|sudo usermod -s /usr/sbin/nologin ${SYSTEM_USERS_WITH_SHELL}"
fi
