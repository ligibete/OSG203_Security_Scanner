#!/usr/bin/env bash
# ==============================================================================
# verify_system.sh - Kiểm tra Tính sẵn sàng của Máy ảo & Hệ điều hành (Task 1.7)
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

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

report_item() {
    local status="$1"
    local title="$2"
    local details="$3"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case "${status}" in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            echo -e "${TAG_PASS} ${BOLD}${title}${NC}: ${details}"
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            echo -e "${TAG_WARN} ${BOLD}${title}${NC}: ${details}"
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            echo -e "${TAG_FAIL} ${BOLD}${title}${NC}: ${details}"
            ;;
    esac
}

echo -e "${BOLD}${BBLUE}"
cat << "EOF"
================================================================================
     OSG203 - BÁO CÁO KIỂM TRA TÍNH SẴN SÀNG MÁY ẢO & HỆ THỐNG (TASK 1.7)
================================================================================
EOF
echo -e "${NC}"

log_header "1. KIỂM TRA MÔI TRƯỜNG ẢO HÓA & PHẦN CỨNG"

# 1.1 Kiểm tra môi trường ảo hóa
VIRT_TYPE="unknown"
if check_command systemd-detect-virt; then
    VIRT_TYPE="$(systemd-detect-virt 2>/dev/null || echo "unknown")"
fi

if [[ "${VIRT_TYPE}" == "vmware" ]] || grep -qi "vmware" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
    report_item "PASS" "Môi trường ảo hóa" "Phát hiện nền tảng ảo hóa VMware Workstation hợp lệ."
else
    report_item "WARN" "Môi trường ảo hóa" "Đang chạy trên nền tảng: ${VIRT_TYPE} (Khuyến nghị sử dụng VMware)."
fi

# 1.2 Kiểm tra tài nguyên CPU
CPU_CORES="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)"
if [[ "${CPU_CORES}" -ge 2 ]]; then
    report_item "PASS" "Số lượng CPU" "Đạt yêu cầu (${CPU_CORES} vCPU)."
else
    report_item "WARN" "Số lượng CPU" "Hiện tại có ${CPU_CORES} vCPU (Khuyến nghị cấu hình tối thiểu 2 vCPU)."
fi

# 1.3 Kiểm tra dung lượng RAM
MEM_MB="$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')"
if [[ "${MEM_MB}" -ge 1800 ]]; then
    report_item "PASS" "Dung lượng RAM" "Đạt yêu cầu (${MEM_MB} MB ~ $(awk "BEGIN {printf \"%.1f\", ${MEM_MB}/1024}") GB)."
else
    report_item "WARN" "Dung lượng RAM" "Dung lượng RAM thấp (${MEM_MB} MB). Khuyến nghị tối thiểu 2048 MB."
fi

# 1.4 Kiểm tra dung lượng đĩa trống
DISK_AVAIL_GB="$(df -BG / 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}')"
if [[ "${DISK_AVAIL_GB}" -ge 5 ]]; then
    report_item "PASS" "Dung lượng ổ đĩa khả dụng" "Đạt yêu cầu (${DISK_AVAIL_GB} GB trống trên phân vùng gốc /)."
else
    report_item "WARN" "Dung lượng ổ đĩa" "Dung lượng trống còn ít (${DISK_AVAIL_GB} GB)."
fi

log_header "2. KIỂM TRA HỆ ĐIỀU HÀNH & KERNEL"

# 2.1 Kiểm tra bản phân phối Linux
OS_INFO="$(get_os_info)"
if echo "${OS_INFO}" | grep -qi "Ubuntu"; then
    report_item "PASS" "Hệ điều hành" "${OS_INFO}"
else
    report_item "WARN" "Hệ điều hành" "${OS_INFO} (Yêu cầu đề tài là Ubuntu Linux)."
fi

# 2.2 Kiểm tra phiên bản Kernel & Kiến trúc
KERNEL_VER="$(uname -r)"
ARCH="$(uname -m)"
if [[ "${ARCH}" == "x86_64" ]]; then
    report_item "PASS" "Kiến trúc hệ thống" "${ARCH} (64-bit)"
else
    report_item "WARN" "Kiến trúc hệ thống" "${ARCH}"
fi
report_item "PASS" "Phiên bản Linux Kernel" "${KERNEL_VER}"

log_header "3. KIỂM TRA MẠNG & KẾT NỐI INTERNET"

# 3.1 Kiểm tra địa chỉ IP
CURRENT_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [[ -n "${CURRENT_IP}" ]] && [[ ! "${CURRENT_IP}" =~ ^169\.254 ]]; then
    report_item "PASS" "Địa chỉ IP mạng" "Đã gán IP hợp lệ: ${CURRENT_IP}"
elif [[ "${CURRENT_IP}" =~ ^169\.254 ]]; then
    report_item "FAIL" "Địa chỉ IP mạng" "Đang nhận IP Link-Local (${CURRENT_IP}). Chưa nhận được IP từ VMware DHCP."
else
    report_item "FAIL" "Địa chỉ IP mạng" "Không tìm thấy địa chỉ IPv4 hoạt động."
fi

# 3.2 Kiểm tra kết nối Internet qua ICMP Ping
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    report_item "PASS" "Kết nối Internet (IP)" "Ping 8.8.8.8 thành công (Mạng hoạt động bình thường)."
else
    report_item "FAIL" "Kết nối Internet (IP)" "Không thể kết nối Internet qua IP 8.8.8.8."
fi

# 3.3 Kiểm tra phân giải tên miền (DNS)
if ping -c 1 -W 2 archive.ubuntu.com >/dev/null 2>&1 || check_command getent && getent hosts archive.ubuntu.com >/dev/null 2>&1; then
    report_item "PASS" "Phân giải tên miền (DNS)" "Phân giải DNS thành công."
else
    report_item "FAIL" "Phân giải tên miền (DNS)" "Không thể phân giải tên miền (Kiểm tra /etc/resolv.conf)."
fi

log_header "4. KIỂM TRA NGƯỜI DÙNG & QUYỀN HẠN HỆ THỐNG"

# 4.1 Kiểm tra người dùng osgadmin
if id "osgadmin" >/dev/null 2>&1; then
    USER_GROUPS="$(id -Gn osgadmin)"
    report_item "PASS" "Tài khoản quản trị" "Tài khoản 'osgadmin' tồn tại. Nhóm: ${USER_GROUPS}"
else
    report_item "WARN" "Tài khoản quản trị" "Chưa phát hiện tài khoản 'osgadmin' (Đang chạy với người dùng: $(whoami))."
fi

# 4.2 Kiểm tra quyền sudo
if sudo -n true 2>/dev/null || [[ "${EUID}" -eq 0 ]]; then
    report_item "PASS" "Quyền quản trị sudo" "Người dùng có đặc quyền sudo hợp lệ."
else
    report_item "WARN" "Quyền quản trị sudo" "Cần mật khẩu sudo hoặc chưa được gán đặc quyền."
fi

log_header "5. KIỂM TRA CÁC GÓI CÔNG CỤ BỔ TRỢ"

REQUIRED_TOOLS=("git" "ssh" "ufw" "python3" "curl" "jq")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if check_command "${tool}"; then
        TOOL_PATH="$(command -v "${tool}")"
        report_item "PASS" "Công cụ ${tool}" "Đã cài đặt tại ${TOOL_PATH}"
    else
        report_item "FAIL" "Công cụ ${tool}" "Chưa được cài đặt (Chạy ./setup_env.sh để tự động cài đặt)."
    fi
done

# Kiểm tra Open-VM-Tools
if dpkg -s open-vm-tools >/dev/null 2>&1; then
    report_item "PASS" "Gói open-vm-tools" "Đã được cài đặt đầy đủ."
else
    report_item "WARN" "Gói open-vm-tools" "Chưa cài đặt gói tối ưu hóa cho VMware."
fi

log_header "6. KIỂM TRA CẤU TRÚC THƯ MỤC DỰ ÁN & GIT"

EXPECTED_DIRS=("core" "scripts" "configs" "docs" "logs")
for dir in "${EXPECTED_DIRS[@]}"; do
    if [[ -d "${BASE_DIR}/${dir}" ]]; then
        report_item "PASS" "Thư mục dự án" "${dir}/ tồn tại hợp lệ."
    else
        report_item "FAIL" "Thư mục dự án" "Thiếu thư mục ${dir}/."
    fi
done

# Kiểm tra kho mã nguồn Git
if [[ -d "${BASE_DIR}/.git" ]]; then
    GIT_BRANCH="$(git -C "${BASE_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    GIT_REMOTE="$(git -C "${BASE_DIR}" remote get-url origin 2>/dev/null || echo "none")"
    report_item "PASS" "Cấu hình Git Repository" "Đã khởi tạo Git (Nhánh: ${GIT_BRANCH}, Remote: ${GIT_REMOTE})"
else
    report_item "FAIL" "Cấu hình Git Repository" "Chưa khởi tạo Git repository."
fi

# ------------------------------------------------------------------------------
# TỔNG KẾT KẾT QUẢ
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BBLUE}================================================================================${NC}"
echo -e "${BOLD}KẾT QUẢ ĐÁNH GIÁ TÍNH SẴN SÀNG HỆ THỐNG:${NC}"
echo -e " - Tổng số bài kiểm tra : ${TOTAL_CHECKS}"
echo -e " - ${BGREEN}Đạt tiêu chuẩn (PASS) : ${PASSED_CHECKS}${NC}"
echo -e " - ${BYELLOW}Cảnh báo (WARN)        : ${WARNING_CHECKS}${NC}"
echo -e " - ${BRED}Chưa đạt (FAIL)       : ${FAILED_CHECKS}${NC}"
echo -e "${BOLD}${BBLUE}================================================================================${NC}\n"

if [[ "${FAILED_CHECKS}" -eq 0 ]]; then
    echo -e "${BOLD}${BGREEN}>>> KẾT LUẬN: HỆ THỐNG ĐÃ SẴN SÀNG CHO GIAI ĐOẠN PHÁT TRIỂN TIẾP THEO! <<<${NC}\n"
    exit 0
else
    echo -e "${BOLD}${BYELLOW}>>> KHUYẾN NGHỊ: Vui lòng chạy lệnh 'sudo ./setup_env.sh' để khắc phục các mục FAIL. <<<${NC}\n"
    exit 1
fi
