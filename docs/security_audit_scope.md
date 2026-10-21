# ĐẶC TẢ PHẠM VI DÒ QUÉT BẢO MẬT MÁY CHỦ UBUNTU
**Dự án:** OSG203 Security Scanner  
**Tiêu chuẩn tham chiếu:** CIS Ubuntu Linux Benchmark v2.0, NIST SP 800-123  
**Đối tượng áp dụng:** Máy chủ Ubuntu Server / Desktop chạy trên nền tảng ảo hóa VMware  

---

## 1. Mục tiêu và Định hướng

Công cụ **OSG203 Security Scanner** được thiết kế nhằm tự động hóa quy trình rà soát, đánh giá các điểm yếu cấu hình (misconfigurations) và các lỗ hổng bảo mật phổ biến trên hệ điều hành Ubuntu Linux, từ đó đưa ra khuyến nghị chuẩn hóa (Hardening).

---

## 2. Bảng Phân loại Phạm vi Dò quét (Audit Scope Matrix)

| Nhóm Kiểm tra | Mã Tiêu chí | Mục kiểm tra chi tiết | Tệp cấu hình / Lệnh kiểm tra | Mức độ nghiêm trọng |
| :--- | :--- | :--- | :--- | :--- |
| **I. Quản lý Người dùng & Xác thực** | `SEC-USR-01` | Kiểm tra tài khoản có UID = 0 ngoài root | `/etc/passwd` | **CRITICAL** |
| | `SEC-USR-02` | Kiểm tra tài khoản không có mật khẩu (Empty password) | `/etc/shadow` | **CRITICAL** |
| | `SEC-USR-03` | Kiểm tra chính sách mật khẩu (Min length, Max age, Warn age) | `/etc/login.defs`, `/etc/pam.d/common-password` | **MEDIUM** |
| | `SEC-USR-04` | Kiểm tra phân quyền tệp tin sudoers và cờ `NOPASSWD` | `/etc/sudoers`, `/etc/sudoers.d/*` | **HIGH** |
| | `SEC-USR-05` | Kiểm tra danh sách tài khoản hệ thống có login shell hợp lệ | `/etc/passwd`, `/etc/shells` | **LOW** |
| **II. Cấu hình Dịch vụ SSH** | `SEC-SSH-01` | Kiểm tra trạng thái cấm đăng nhập root từ xa (`PermitRootLogin`) | `/etc/ssh/sshd_config`, `sshd_config.d/*` | **CRITICAL** |
| | `SEC-SSH-02` | Kiểm tra xác thực bằng mật khẩu rỗng (`PermitEmptyPasswords`) | `/etc/ssh/sshd_config` | **CRITICAL** |
| | `SEC-SSH-03` | Kiểm tra số lần thử đăng nhập tối đa (`MaxAuthTries <= 4`) | `/etc/ssh/sshd_config` | **MEDIUM** |
| | `SEC-SSH-04` | Kiểm tra cổng dịch vụ SSH mặc định (Port 22 vs custom) | `/etc/ssh/sshd_config`, `ss -tulpn` | **LOW** |
| | `SEC-SSH-05` | Kiểm tra hỗ trợ thuật toán mã hóa lỗi thời (Protocol 1, weak ciphers) | `/etc/ssh/sshd_config` | **HIGH** |
| **III. Tường lửa & Mạng** | `SEC-NET-01` | Trạng thái hoạt động của tường lửa UFW (`Status: active`) | `ufw status verbose` | **HIGH** |
| | `SEC-NET-02` | Chính sách mặc định của tường lửa (Default incoming: deny) | `ufw status verbose` | **HIGH** |
| | `SEC-NET-03` | Rà soát danh sách các cổng đang mở lắng nghe (Listening ports) | `ss -tulpn`, `netstat -tuln` | **MEDIUM** |
| | `SEC-NET-04` | Phát hiện các dịch vụ không an toàn đang chạy (telnet, rsh, vsftpd) | `systemctl list-units`, `ss` | **HIGH** |
| | `SEC-NET-05` | Kiểm tra tính năng IP Forwarding (`net.ipv4.ip_forward == 0`) | `sysctl net.ipv4.ip_forward` | **MEDIUM** |
| **IV. Phân quyền Hệ thống Tệp** | `SEC-FIL-01` | Phân quyền tệp tin nhạy cảm `/etc/shadow` (phải là 600 hoặc 640) | `stat -c "%a" /etc/shadow` | **CRITICAL** |
| | `SEC-FIL-02` | Phân quyền tệp tin `/etc/passwd` (phải là 644) | `stat -c "%a" /etc/passwd` | **HIGH** |
| | `SEC-FIL-03` | Phân quyền thư mục `/root` và tệp sudoers | `stat -c "%a" /root`, `/etc/sudoers` | **HIGH** |
| | `SEC-FIL-04` | Quét các tệp nhị phân có gán cờ SUID/SGID nguy hiểm | `find / -perm -4000 2>/dev/null` | **MEDIUM** |
| | `SEC-FIL-05` | Quét tệp tin và thư mục có quyền ghi tự do (World-writable) | `find / -xdev -type d -perm -0002` | **MEDIUM** |
| **V. Tiến trình & Tác vụ Lập lịch** | `SEC-PRC-01` | Kiểm tra phân quyền thư mục cron (`/etc/cron.*`, `/etc/crontab`) | `ls -la /etc/cron*` | **HIGH** |
| | `SEC-PRC-02` | Kiểm tra danh sách Cron job của người dùng root | `crontab -u root -l` | **MEDIUM** |
| | `SEC-PRC-03` | Rà soát các tiến trình đang chạy dưới quyền root không cần thiết | `ps aux` | **LOW** |
| **VI. Nhật ký & Giám sát Hệ thống** | `SEC-LOG-01` | Kiểm tra trạng thái dịch vụ ghi log `rsyslog` hoặc `systemd-journald` | `systemctl is-active rsyslog` | **MEDIUM** |
| | `SEC-LOG-02` | Kiểm tra trạng thái dịch vụ kiểm toán an ninh `auditd` | `systemctl is-active auditd` | **MEDIUM** |
| | `SEC-LOG-03` | Kiểm tra cấu hình log rotation (`/etc/logrotate.conf`) | `cat /etc/logrotate.conf` | **LOW** |
| **VII. Kernel & Tham số Bộ nhớ** | `SEC-KRN-01` | Kiểm tra tính năng ASLR (Address Space Layout Randomization = 2) | `cat /proc/sys/kernel/randomize_va_space` | **HIGH** |
| | `SEC-KRN-02` | Chống tấn công SYN Flood (`net.ipv4.tcp_syncookies = 1`) | `sysctl net.ipv4.tcp_syncookies` | **HIGH** |
| | `SEC-KRN-03` | Vô hiệu hóa tính năng ICMP Redirects | `sysctl net.ipv4.conf.all.accept_redirects` | **MEDIUM** |

---

## 3. Tiêu chí Đánh giá và Phân loại Kết quả

Mỗi hạng mục kiểm tra khi thực thi sẽ trả về một trong các trạng thái sau:
1. `[PASS]`: Cấu hình tuân thủ tuyệt đối tiêu chuẩn bảo mật.
2. `[WARN]`: Cấu hình ở mức cảnh báo, có nguy cơ tiềm ẩn nhưng chưa gây ảnh hưởng ngay lập tức.
3. `[FAIL]`: Cấu hình vi phạm nghiêm trọng tiêu chuẩn bảo mật, cần khắc phục ngay.
4. `[INFO]`: Thông tin cấu hình hiện tại của hệ thống để quản trị viên tham khảo.
