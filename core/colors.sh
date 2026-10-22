#!/usr/bin/env bash
# ==============================================================================
# core/colors.sh - Bảng mã màu ANSI và biểu tượng hiển thị cho OSG203 Scanner
# ==============================================================================

# Định dạng văn bản
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'
export NC='\033[0m' # No Color / Reset

# Mã màu cơ bản
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

# Mã màu đậm (Bold colors)
export BRED='\033[1;31m'
export BGREEN='\033[1;32m'
export BYELLOW='\033[1;33m'
export BBLUE='\033[1;34m'
export BPURPLE='\033[1;35m'
export BCYAN='\033[1;36m'
export BWHITE='\033[1;37m'

# Nhãn trạng thái chuẩn hóa
export TAG_INFO="${BCYAN}[INFO]${NC}"
export TAG_PASS="${BGREEN}[PASS]${NC}"
export TAG_WARN="${BYELLOW}[WARN]${NC}"
export TAG_FAIL="${BRED}[FAIL]${NC}"
export TAG_CHECK="${BPURPLE}[CHECK]${NC}"
