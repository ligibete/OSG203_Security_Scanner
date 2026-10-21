# QUY CHUẨN LẬP TRÌNH VÀ PHÁT TRIỂN DỰ ÁN OSG203
**Dự án:** OSG203 Security Scanner - Automated Server Hardening Tool  
**Ngôn ngữ chính:** Bash Shell Script, Python 3  
**Hệ điều hành mục tiêu:** Ubuntu Server 22.04 / 24.04 LTS  

---

## 1. Quy chuẩn cấu trúc mã nguồn Bash Script

1. **Shebang bắt buộc:** Dòng đầu tiên của mọi file script Bash phải là:
   ```bash
   #!/usr/bin/env bash
   ```
2. **Xử lý lỗi nghiêm ngặt (Strict Mode):** Mọi script thực thi phải khai báo:
   ```bash
   set -euo pipefail
   IFS=$'\n\t'
   ```
   - `-e`: Dừng script ngay khi có lệnh trả về lỗi (exit code != 0).
   - `-u`: Báo lỗi khi sử dụng biến chưa được định nghĩa.
   - `-o pipefail`: Trả về mã lỗi của lệnh thất bại đầu tiên trong pipeline.

3. **Kiểm tra quyền quản trị (Root/Sudo):**
   - Với các script kiểm tra hoặc can thiệp cấu hình hệ thống, bắt buộc kiểm tra quyền root ở phần đầu script:
   ```bash
   if [[ "${EUID}" -ne 0 ]]; then
       echo "[ERROR] Script này yêu cầu quyền root. Vui lòng chạy lại với sudo." >&2
       exit 1
   fi
   ```

4. **Quy tắc đặt tên file và thư mục:**
   - Script kiểm tra bảo mật độc lập: `scripts/check_<ten_module>.sh` (Ví dụ: `check_users.sh`, `check_ssh.sh`, `check_firewall.sh`).
   - Script hàm dùng chung: `core/<ten_thu_vien>.sh` (Ví dụ: `utils.sh`, `logger.sh`).
   - Tên file chỉ dùng chữ thường, số và dấu gạch dưới `_`. Không dùng dấu cách hoặc ký tự đặc biệt.

5. **Quy tắc đặt tên biến và hàm:**
   - Hằng số và biến môi trường: Viết hoa toàn bộ, cách nhau bằng gạch dưới (Ví dụ: `PROJECT_ROOT`, `LOG_DIR`, `DEFAULT_PORT`).
   - Biến cục bộ trong hàm: Khai báo với từ khóa `local`, viết thường (Ví dụ: `local check_result=0`).
   - Tên hàm: Viết thường, động từ đứng trước (Ví dụ: `audit_password_policy()`, `check_port_open()`, `log_info()`).

## 2. Quy chuẩn Logging và Đầu ra (Output)

1. Mọi thông báo hiển thị trên màn hình console phải có định dạng tiêu chuẩn với mã màu ANSI:
   - `[INFO]`: Màu xanh lục (Green) - Thông tin tiến trình bình thường.
   - `[WARN]`: Màu vàng (Yellow) - Cảnh báo nguy cơ bảo mật mức trung bình.
   - `[FAIL]`: Màu đỏ (Red) - Vi phạm bảo mật nghiêm trọng hoặc lỗi thực thi.
   - `[PASS]`: Màu xanh dương / lục đậm - Cấu hình an toàn đạt chuẩn.

2. Mọi hoạt động kiểm tra phải được ghi đồng thời ra tệp log trong thư mục `logs/` theo định dạng:
   ```
   [YYYY-MM-DD HH:MM:SS] [LEVEL] [MODULE] Nội dung log
   ```

## 3. Quy chuẩn An toàn và Bảo mật trong Script

1. **Tránh Shell Injection:** Luôn bọc biến trong dấu ngoặc kép `"$VAR"`.
2. **Không mã hóa cứng mật khẩu (Hardcoded Secrets):** Tuyệt đối không lưu mật khẩu hoặc private key trong code.
3. **Chế độ kiểm tra an toàn (Non-destructive Audit):**
   - Các script `check_*.sh` ở giai đoạn này chỉ thực hiện **ĐỌC & DÒ QUÉT (Audit / Read-only)**, tuyệt đối không tự ý ghi đè file cấu hình hệ thống khi chưa có cờ xác nhận `--fix` hoặc `--remediate`.
4. **Sao lưu trước khi thay đổi:** Bất kỳ thao tác can thiệp nào phải tạo bản sao lưu với đuôi `.bak.<timestamp>`.
