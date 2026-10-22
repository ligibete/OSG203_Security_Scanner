#!/usr/bin/env bash
# ==============================================================================
# setup_env.sh - Tự động hóa Thiết lập Môi trường Dự án OSG203 (Task 1.5 & 1.6)
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nạp thư viện lõi
# shellcheck source=core/colors.sh
source "${BASE_DIR}/core/colors.sh"
# shellcheck source=core/logger.sh
source "${BASE_DIR}/core/logger.sh"
# shellcheck source=core/utils.sh
source "${BASE_DIR}/core/utils.sh"

require_root

log_header "GIAI ĐOẠN 1: THIẾT LẬP MÔI TRƯỜNG VÀ CÀI ĐẶT GÓI PHỤ TRỢ (Task 1.5 & 1.6)"

# ------------------------------------------------------------------------------
# 1. Cập nhật hệ thống kho gói APT
# ------------------------------------------------------------------------------
log_info "Đang cập nhật danh mục gói phần mềm (apt-get update)..."
apt-get update -y >/dev/null 2>&1 || log_warn "Cảnh báo: apt-get update có thông báo lỗi, tiếp tục cài đặt..."

# ------------------------------------------------------------------------------
# 2. Cài đặt các gói phụ trợ cho Môi trường ảo hóa VMware (Task 1.6)
# ------------------------------------------------------------------------------
log_info "Kiểm tra và cài đặt Open-VM-Tools cho môi trường ảo hóa VMware..."
VM_PACKAGES=("open-vm-tools" "open-vm-tools-desktop")
for pkg in "${VM_PACKAGES[@]}"; do
    if dpkg -s "${pkg}" >/dev/null 2>&1; then
        log_pass "Gói ${pkg} đã được cài đặt."
    else
        log_info "Đang cài đặt gói ${pkg}..."
        apt-get install -y --no-install-recommends "${pkg}" >/dev/null 2>&1 && log_pass "Cài đặt ${pkg} thành công." || log_warn "Không thể cài đặt ${pkg} (có thể bỏ qua nếu đang chạy server thuần)."
    fi
done

# ------------------------------------------------------------------------------
# 3. Cài đặt các công cụ quản trị, giám sát và bảo mật cần thiết (Task 1.6)
# ------------------------------------------------------------------------------
log_info "Cài đặt các gói quản trị và bảo mật cốt lõi..."
CORE_PACKAGES=(
    "openssh-server"
    "git"
    "curl"
    "wget"
    "net-tools"
    "ufw"
    "auditd"
    "audispd-plugins"
    "jq"
    "nmap"
    "tree"
    "python3"
    "python3-pip"
    "lynis"
)

for pkg in "${CORE_PACKAGES[@]}"; do
    if dpkg -s "${pkg}" >/dev/null 2>&1; then
        log_pass "Gói ${pkg} đã sẵn sàng."
    else
        log_info "Đang cài đặt ${pkg}..."
        if apt-get install -y "${pkg}" >/dev/null 2>&1; then
            log_pass "Cài đặt ${pkg} thành công."
        else
            log_warn "Không thể cài đặt ${pkg} qua apt."
        fi
    fi
done

# Kích hoạt và bật dịch vụ SSH
if systemctl is-active --quiet ssh; then
    log_pass "Dịch vụ OpenSSH Server đang hoạt động."
else
    log_info "Kích hoạt và khởi động dịch vụ SSH..."
    systemctl enable --now ssh >/dev/null 2>&1 || true
    log_pass "Đã kích hoạt SSH."
fi

# ------------------------------------------------------------------------------
# 4. Cấu hình phân quyền hệ thống & chuẩn hóa môi trường làm việc (Task 1.5)
# ------------------------------------------------------------------------------
log_header "CẤU HÌNH PHÂN QUYỀN VÀ MÔI TRƯỜNG LÀM VIỆC (Task 1.5)"

# Tạo nhóm quản trị kiểm toán bảo mật chuyên dụng
SEC_GROUP="osgsec"
if getent group "${SEC_GROUP}" >/dev/null 2>&1; then
    log_pass "Nhóm bảo mật '${SEC_GROUP}' đã tồn tại."
else
    log_info "Đang tạo nhóm quản trị '${SEC_GROUP}'..."
    groupadd "${SEC_GROUP}"
    log_pass "Đã tạo nhóm '${SEC_GROUP}' thành công."
fi

# Thêm tài khoản osgadmin vào nhóm osgsec
AUDIT_USER="osgadmin"
if id "${AUDIT_USER}" >/dev/null 2>&1; then
    usermod -aG "${SEC_GROUP}" "${AUDIT_USER}"
    log_pass "Đã gán người dùng '${AUDIT_USER}' vào nhóm '${SEC_GROUP}'."
fi

# Cấu hình file sudoers chuẩn hóa cho dự án
SUDOERS_FILE="/etc/sudoers.d/osg203_audit"
log_info "Thiết lập cấu hình phân quyền sudoers tại ${SUDOERS_FILE}..."
cat << 'EOF' > "${SUDOERS_FILE}"
# OSG203 Security Scanner - Dedicated Audit Privileges
# Cho phép thành viên nhóm osgsec chạy các lệnh kiểm tra không cần nhập mật khẩu
%osgsec ALL=(ALL) NOPASSWD: /usr/sbin/ufw, /usr/sbin/auditctl, /usr/bin/netstat, /usr/bin/ss, /usr/sbin/sshd
EOF
chmod 0440 "${SUDOERS_FILE}"
visudo -cf "${SUDOERS_FILE}" >/dev/null 2>&1 && log_pass "Cấu hình sudoers hợp lệ và đã áp dụng."

# Thiết lập biến môi trường dự án toàn hệ thống
ENV_PROFILE="/etc/profile.d/osg203_env.sh"
log_info "Thiết lập biến môi trường chuẩn hóa tại ${ENV_PROFILE}..."
cat << EOF > "${ENV_PROFILE}"
# OSG203 Security Scanner Environment Setup
export OSG_PROJECT_ROOT="${BASE_DIR}"
export PATH="\$PATH:\${OSG_PROJECT_ROOT}/scripts"
alias osg-scan="sudo \${OSG_PROJECT_ROOT}/main.sh"
alias osg-verify="\${OSG_PROJECT_ROOT}/verify_system.sh"
alias osg-log="tail -f \${OSG_PROJECT_ROOT}/logs/scan_\$(date +'%Y%m%d').log"
EOF
chmod 0644 "${ENV_PROFILE}"
log_pass "Đã tạo biến môi trường và alias điều hành thành công."

# Phân quyền thư mục dự án
log_info "Chuẩn hóa phân quyền thư mục dự án: ${BASE_DIR}..."
chmod -R 755 "${BASE_DIR}/core" "${BASE_DIR}/scripts" 2>/dev/null || true
chmod +x "${BASE_DIR}"/*.sh 2>/dev/null || true
log_pass "Hoàn thành chuẩn hóa phân quyền thư mục dự án."

echo -e "\n${BOLD}${BGREEN}>>> HOÀN THÀNH THIẾT LẬP MÔI TRƯỜNG CHO TASK 1.5 & TASK 1.6! <<<${NC}\n"
