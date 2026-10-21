#!/usr/bin/env bash
# ==============================================================================
# scripts/check_permissions.sh - Module Kiểm tra Phân quyền Tệp tin Hệ thống
# Mã tiêu chí: SEC-FIL-01 đến SEC-FIL-05
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

log_header "MODULE 4: KIỂM TRA PHÂN QUYỀN TỆP TIN NHẠY CẢM & SUID"

# 1. Kiểm tra phân quyền /etc/shadow
log_info "[SEC-FIL-01] Kiểm tra phân quyền tệp tin /etc/shadow..."
SHADOW_PERM=$(stat -c "%a" /etc/shadow)
SHADOW_OWNER=$(stat -c "%U:%G" /etc/shadow)
if [[ "${SHADOW_PERM}" == "600" ]] || [[ "${SHADOW_PERM}" == "640" ]] || [[ "${SHADOW_PERM}" == "000" ]]; then
    log_pass "Phân quyền /etc/shadow an toàn: ${SHADOW_PERM} (Sở hữu: ${SHADOW_OWNER})."
else
    log_fail "Phân quyền /etc/shadow NGUY HIỂM: ${SHADOW_PERM} (Yêu cầu tối đa: 0640)."
fi

# 2. Kiểm tra phân quyền /etc/passwd
log_info "[SEC-FIL-02] Kiểm tra phân quyền tệp tin /etc/passwd..."
PASSWD_PERM=$(stat -c "%a" /etc/passwd)
if [[ "${PASSWD_PERM}" == "644" ]]; then
    log_pass "Phân quyền /etc/passwd đạt chuẩn: ${PASSWD_PERM}."
else
    log_warn "Phân quyền /etc/passwd: ${PASSWD_PERM} (Chuẩn: 0644)."
fi

# 3. Quét các tệp nhị phân có cờ SUID bất thường
log_info "[SEC-FIL-04] Quét các tệp thực thi có gán quyền SUID (SetUID root)..."
SUID_FILES=$(find /usr/bin /usr/sbin /bin /sbin -perm -4000 -type f 2>/dev/null | sort || true)
SUID_COUNT=$(echo "${SUID_FILES}" | grep -c '.' || echo 0)
log_info "Tìm thấy ${SUID_COUNT} tệp tin có cờ SUID trong các thư mục hệ thống."

# Cảnh báo nếu các lệnh nguy hiểm bị gán SUID
DANGEROUS_SUID=("vim" "vi" "nano" "find" "cp" "mv" "bash" "sh" "python" "python3" "perl")
FOUND_DANGEROUS=0
for d_bin in "${DANGEROUS_SUID[@]}"; do
    if echo "${SUID_FILES}" | grep -qE "/${d_bin}$"; then
        log_fail "CẢNH BÁO LỖ HỔNG LEO THANG ĐẶC QUYỀN (GTFOBins): ${d_bin} bị gán SUID!"
        FOUND_DANGEROUS=1
    fi
done

if [[ "${FOUND_DANGEROUS}" -eq 0 ]]; then
    log_pass "Không phát hiện tệp tin nguy hiểm nào bị lạm dụng cờ SUID."
fi

# 4. Quét tệp tin có quyền ghi tự do (World-Writable)
log_info "[SEC-FIL-05] Rà soát các tệp tin có quyền ghi tự do (World-writable)..."
WW_FILES=$(find /etc /var/log -xdev -type f -perm -0002 2>/dev/null | head -n 5 || true)
if [[ -z "${WW_FILES}" ]]; then
    log_pass "Không phát hiện tệp tin nhạy cảm nào bị quyền ghi cho mọi người (world-writable)."
else
    log_fail "Phát hiện tệp tin world-writable nguy hiểm trong /etc hoặc /var/log: ${WW_FILES}"
fi

echo -e "\n${BOLD}${BGREEN}Hoàn thành quét Module 4 (File Permissions).${NC}\n"
