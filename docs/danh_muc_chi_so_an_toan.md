# DANH MỤC CÁC CHỈ SỐ AN TOÀN HỆ THỐNG LINUX (OSG203)
*Người soạn thảo: Minh*

## 1. Dịch vụ Mạng & Tường lửa (Network & Firewall)
- Trạng thái UFW: Bắt buộc `active`.
- Chính sách mặc định: Chặn kết nối vào (Deny incoming), Cho phép kết nối ra (Allow outgoing).
- Quản lý Port: Mở các port thiết yếu (22, 80, 443). Cảnh báo nghiêm trọng nếu mở các port không an toàn (21, 23).

## 2. Dịch vụ Truy cập từ xa (OpenSSH)
- Cấm đăng nhập bằng quyền `root` (PermitRootLogin no).
- Vô hiệu hóa mật khẩu trống (PermitEmptyPasswords no).
- Giới hạn số lần thử xác thực tối đa.

## 3. Xác thực người dùng (PAM & Passwords)
- Độ dài mật khẩu: Tối thiểu 8 ký tự.
- Độ phức tạp: Bắt buộc có chữ hoa, chữ thường, số và ký tự đặc biệt.
- Khóa tài khoản (Lockout): Khóa 15 phút nếu nhập sai mật khẩu 5 lần.

## 4. Phân quyền Tệp tin & Người dùng
- Kiểm tra quyền sở hữu các file nhạy cảm (`/etc/passwd`, `/etc/shadow`).
- Cảnh báo các tệp tin có cờ SUID/SGID nguy hiểm.
