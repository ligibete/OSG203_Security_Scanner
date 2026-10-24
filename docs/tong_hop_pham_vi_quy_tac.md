# BÁO CÁO TỔNG HỢP & PHẠM VI DÒ QUÉT (Task 2.1 & 2.9)

## 1. Phạm vi hệ thống (Scope)
- **Hệ điều hành mục tiêu:** Ubuntu Linux.
- **Quyền hạn yêu cầu:** Quyền `root` hoặc tài khoản thuộc nhóm `sudo`.
- **Cấu trúc lưu trữ:** Mọi quy tắc được lưu tại thư mục `configs/` dưới định dạng `.conf`.

## 2. Tổng hợp các Module quy tắc
1. **Mạng & Tường lửa (`firewall_rules.conf`):** Trạng thái UFW, chính sách Inbound/Outbound, port.
2. **OpenSSH (`ssh_rules.conf`):** Chặn root, chặn pass rỗng, cấu hình port 22.
3. **Xác thực (`pam_rules.conf`, `login_rules.conf`):** Độ phức tạp, khóa tài khoản, tuổi thọ mật khẩu (90 ngày).
4. **Phân quyền (`permission_rules.conf`):** Quyền an toàn cho file hệ thống quan trọng.

## 3. Kết luận
Toàn bộ các quy tắc đã được đồng bộ, bám sát chuẩn an toàn hệ thống và không có sự xung đột.
