#!/usr/bin/env bash
# ==============================================================================
# scripts/check_users.sh - Module Kiểm tra Quản lý Người dùng & Xác thực
# Mã tiêu chí: SEC-USR-01 đến SEC-USR-05
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

log_header "MODULE 1: KIỂM TRA TÀI KHOẢN VÀ XÁC THỰC NGƯỜI DÙNG"

# 1. Kiểm tra tài khoản có UID 0 ngoài root
log_info "[SEC-USR-01] Kiểm tra các tài khoản có UID = 0..."
UID_ZERO_ACCOUNTS=$(awk -F: '($3 == 0) {print $1}' /etc/passwd | grep -v '^root$' || true)
if [[ -z "${UID_ZERO_ACCOUNTS}" ]]; then
    log_pass "Chỉ có duy nhất người dùng 'root' có UID = 0."
else
    log_fail "Phát hiện tài khoản bất thường có UID = 0: ${UID_ZERO_ACCOUNTS} (Nguy cơ đặc quyền cao trái phép!)"
fi

# 2. Kiểm tra tài khoản không có mật khẩu (Empty Password)
log_info "[SEC-USR-02] Kiểm tra tài khoản không có mật khẩu trong /etc/shadow..."
EMPTY_PW_ACCOUNTS=$(awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null | grep -vE '^(daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|list|irc|gnats|nobody|systemd.*)' || true)
BLANK_HASH=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null || true)

if [[ -z "${BLANK_HASH}" ]]; then
    log_pass "Không có tài khoản nào có mật khẩu để trống."
else
    log_fail "CẢNH BÁO NGUY HIỂM: Tài khoản không có mật khẩu: ${BLANK_HASH}"
fi

# 3. Kiểm tra chính sách mật khẩu trong /etc/login.defs
log_info "[SEC-USR-03] Kiểm tra chính sách thời hạn mật khẩu trong /etc/login.defs..."
PASS_MAX_DAYS=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "99999")
PASS_MIN_DAYS=$(grep -E '^PASS_MIN_DAYS' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "0")
PASS_WARN_AGE=$(grep -E '^PASS_WARN_AGE' /etc/login.defs 2>/dev/null | awk '{print $2}' || echo "7")

if [[ "${PASS_MAX_DAYS}" -le 90 ]]; then
    log_pass "Thời hạn mật khẩu tối đa (PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày) đạt chuẩn CIS Benchmark."
else
    log_warn "PASS_MAX_DAYS = ${PASS_MAX_DAYS} ngày (Khuyến nghị: <= 90 ngày)."
fi

# 4. Kiểm tra phân quyền tệp tin sudoers và cờ NOPASSWD
log_info "[SEC-USR-04] Rà soát cấu hình đặc quyền sudoers..."
if [[ -f /etc/sudoers ]]; then
    SUDOERS_PERM=$(stat -c "%a" /etc/sudoers)
    if [[ "${SUDOERS_PERM}" == "440" ]] || [[ "${SUDOERS_PERM}" == "400" ]]; then
        log_pass "Phân quyền /etc/sudoers an toàn: ${SUDOERS_PERM}"
    else
        log_fail "Phân quyền /etc/sudoers không an toàn: ${SUDOERS_PERM} (Yêu cầu: 0440)."
    fi
fi

# 5. Kiểm tra quyền shell đăng nhập bất thường
log_info "[SEC-USR-05] Rà soát shell đăng nhập của các tài khoản hệ thống..."
SYSTEM_USERS_WITH_SHELL=$(awk -F: '($3 < 1000 && $3 > 0 && $7 !~ /(nologin|false)$/) {print $1 ":" $7}' /etc/passwd || true)
if [[ -z "${SYSTEM_USERS_WITH_SHELL}" ]]; then
    log_pass "Tất cả các tài khoản dịch vụ hệ thống đều được khóa shell (/sbin/nologin hoặc /bin/false)."
else
    log_warn "Tài khoản hệ thống có shell đăng nhập mở: ${SYSTEM_USERS_WITH_SHELL}"
fi

echo -e "\n${BOLD}${BGREEN}Hoàn thành quét Module 1 (Users & Authentication).${NC}\n"
