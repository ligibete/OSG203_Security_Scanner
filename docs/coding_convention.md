# QUY CHUẨN CODE DỰ ÁN OSG203

1. Tất cả script kiểm tra đặt trong thư mục: `scripts/`
2. Đặt tên file Bash dạng: `check_<ten_module>.sh` (Ví dụ: `check_ufw.sh`)
3. Dòng đầu tiên của Bash Script phải là: `#!/usr/bin/env bash`
4. Bắt buộc kiểm tra quyền root (`EUID == 0`) trước khi thực thi
EOF4

cat << 'EOF' > docs/coding_convention.md
# QUY CHUẨN CODE DỰ ÁN OSG203

1. Tất cả script kiểm tra đặt trong thư mục: `scripts/`
2. Đặt tên file Bash dạng: `check_<ten_module>.sh` (Ví dụ: `check_ufw.sh`)
3. Dòng đầu tiên của Bash Script phải là: `#!/usr/bin/env bash`
4. Bắt buộc kiểm tra quyền root (`EUID == 0`) trước khi thực thi
