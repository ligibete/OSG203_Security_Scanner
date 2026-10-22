#!/usr/bin/env bash
# ==============================================================================
# core/utils.sh - Các hàm tiện ích dùng chung trong dự án OSG203
# ==============================================================================

# Kiểm tra quyền root
require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo -e "\033[1;31m[ERROR]\033[0m Lệnh này yêu cầu quyền quản trị root/sudo để thực hiện kiểm tra chuyên sâu." >&2
        echo "Vui lòng chạy lại với lệnh: sudo $0 $*" >&2
        exit 1
    fi
}

# Kiểm tra xem một lệnh/gói phần mềm đã được cài đặt hay chưa
check_command() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Lấy thông tin phiên bản hệ điều hành
get_os_info() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${NAME} ${VERSION}"
    else
        uname -srm
    fi
}

# Lấy thông tin phần cứng máy ảo
get_hardware_info() {
    local cpus
    local mem_total
    cpus="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)"
    mem_total="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
    echo "CPU: ${cpus} cores | RAM: ${mem_total}"
}
