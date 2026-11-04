#!/bin/bash

echo "[*] Đang phân tích môi trường thực thi OS..."

# Cách 1: Check file .dockerenv
if [ -f /.dockerenv ]; then
    echo "[+] XÁC NHẬN: Hệ thống Tactical Scanner ĐANG chạy trong môi trường Docker Container."
# Cách 2: Check cgroup của tiến trình gốc (PID 1)
elif grep -Eq '(lxc|docker)' /proc/1/cgroup 2>/dev/null; then
    echo "[+] XÁC NHẬN: Hệ thống ĐANG chạy trong Docker (Xác minh qua Control Groups)."
else
    echo "[-] CẢNH BÁO: Hệ thống đang chạy trực tiếp trên Host (Không qua Docker)."
fi
