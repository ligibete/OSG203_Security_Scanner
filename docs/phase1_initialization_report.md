# BÁO CÁO TỔNG KẾT & ĐÁNH GIÁ HOÀN THÀNH GIAI ĐOẠN KHỞI TẠO (PHASE 1)
**Học phần:** OSG203 - Hệ điều hành (Operating Systems)  
**Tên dự án:** OSG203 Security Scanner - Automated Server Hardening Tool  
**Trạng thái:** Hoàn thành toàn diện Giai đoạn 1 (Giai đoạn Khởi tạo Môi trường)  
**Ngày báo cáo:** 21/10/2026  

---

## 1. Bảng Tổng hợp Tiến độ và Kết quả Công việc (Phase 1)

| Mã Task | Tên công việc (Task Title) | Yêu cầu chuẩn | Kết quả thực tế đạt được | Đánh giá |
| :---: | :--- | :--- | :--- | :---: |
| **1.1** | **Cài đặt máy ảo Ubuntu Server và phần mềm VMware** | Thiết lập máy ảo Ubuntu trên VMware Workstation, cấp phát tối thiểu 2 vCPU, 2-4GB RAM, đĩa cứng 20GB. | Máy ảo `osg203_project` đã được cài đặt trên VMware Workstation 17 Pro, cấu hình 2 vCPU, 4GB RAM, tài khoản `osgadmin`. | **ĐẠT (PASS)** |
| **1.2** | **Thiết lập Git repository và thống nhất quy trình làm việc nhóm** | Khởi tạo kho mã nguồn Git, thiết lập nhánh, quy tắc đặt tên nhánh, commit convention, phân chia công việc. | Đã khởi tạo Git tại `https://github.com/ligibete/OSG203_Security_Scanner.git`. Xây dựng hoàn chỉnh tài liệu quy trình `docs/git_workflow.md` theo chuẩn Conventional Commits & Gitflow thu gọn. | **ĐẠT (PASS)** |
| **1.3** | **Xác định phạm vi các cấu hình cần dò quét trên máy chủ** | Lập danh mục chi tiết các điểm cấu hình bảo mật cần kiểm tra trên Ubuntu theo tiêu chuẩn CIS Benchmark. | Xây dựng tài liệu ma trận phạm vi `docs/security_audit_scope.md` gồm 7 nhóm tiêu chí chuyên sâu (24 mã kiểm tra từ tài khoản, SSH, UFW, phân quyền tệp, SUID, dịch vụ đến Kernel sysctl). | **ĐẠT (PASS)** |
| **1.4** | **Khởi tạo quy chuẩn thư mục dự án và môi trường phát triển** | Thiết lập cấu trúc thư mục phân tầng chuyên nghiệp (`core/`, `scripts/`, `configs/`, `docs/`, `logs/`), xây dựng tài liệu quy chuẩn code. | Hoàn thiện 100% cấu trúc cây thư mục dự án, tệp cấu hình tham số `configs/audit_rules.conf`, quy chuẩn lập trình `docs/coding_convention.md` (Shebang, strict mode, bẫy lỗi, quy tắc đặt tên). | **ĐẠT (PASS)** |
| **1.5** | **Cấu hình phân quyền hệ thống & chuẩn hóa môi trường làm việc** | Tạo nhóm bảo mật, phân quyền sudo hạn chế, thiết lập biến môi trường dự án toàn hệ thống. | Tạo script tự động `setup_env.sh` khởi tạo nhóm `osgsec`, phân quyền sudoers chuyên biệt tại `/etc/sudoers.d/osg203_audit`, tạo biến môi trường toàn hệ thống `/etc/profile.d/osg203_env.sh` và alias điều hành (`osg-scan`, `osg-verify`, `osg-log`). | **ĐẠT (PASS)** |
| **1.6** | **Thiết lập môi trường ảo hóa & cài đặt các gói phụ trợ** | Cài đặt `open-vm-tools`, `openssh-server`, tường lửa `ufw`, công cụ kiểm toán `auditd`, mạng `net-tools`, `jq`, `python3`. | Tích hợp trong script `setup_env.sh` tự động cài đặt và kích hoạt 14 gói phần mềm cốt lõi phục vụ bảo mật và quản trị hệ thống Linux. | **ĐẠT (PASS)** |
| **1.7** | **Kiểm tra tính sẵn sàng của máy ảo & hệ điều hành Ubuntu** | Xây dựng cơ chế tự động đánh giá readiness của máy ảo, tài nguyên phần cứng, mạng, quyền sudo, gói phần mềm. | Phát triển script kiểm thử tự động `verify_system.sh` kiểm tra 18 chỉ số tính sẵn sàng, hiển thị kết quả màu sắc trực quan [PASS]/[WARN]/[FAIL] và sinh báo cáo tổng hợp. | **ĐẠT (PASS)** |
| **1.8** | **Tổng kết & đánh giá hoàn thành giai đoạn khởi tạo** | Đánh giá nghiệm thu kết quả Giai đoạn 1, phân tích điểm cần lưu ý và lập kế hoạch cho Giai đoạn 2. | Hoàn thành tài liệu tổng kết `docs/phase1_initialization_report.md`, cam kết tiến độ và chất lượng cho các cột mốc tiếp theo của đồ án OSG203. | **ĐẠT (PASS)** |

---

## 2. Đánh giá Chi tiết & Phát hiện Kỹ thuật (Technical Findings)

1. **Vấn đề Card mạng Link-Local (APIPA `169.254.x.x`):**
   - *Hiện tượng:* Máy ảo Ubuntu khi khởi động nhận dải IP APIPA (`169.254.40.88`) thay vì IP từ DHCP của VMware NAT (`192.168.120.x`).
   - *Nguyên nhân:* Tiến trình NetworkManager trong máy ảo gửi DHCP request trước khi card mạng ảo VMware hoàn tất kết nối, dẫn đến việc tự động fallback về Link-Local IPv4.
   - *Giải pháp khắc phục:* Trong terminal Ubuntu, thực hiện lệnh `sudo dhclient -v` hoặc `sudo systemctl restart NetworkManager` để nhận ngay IP NAT chính thức và kết nối Internet thông suốt.

2. **Cơ chế OpenSSH Server:**
   - Trên bản cài đặt Ubuntu Desktop, gói `openssh-server` mặc định chưa được kích hoạt. Script `setup_env.sh` đã được thiết kế tự động cài đặt `openssh-server` và khởi chạy dịch vụ qua systemd, bảo đảm kết nối SSH an toàn từ xa.

---

## 3. Kế hoạch Triển khai Giai đoạn 2 (Phase 2 Roadmap)

1. **Phát triển hoàn thiện các Module Quét chuyên sâu:**
   - Hoàn thiện mở rộng module `check_users.sh`, `check_ssh.sh`, `check_firewall.sh`, `check_permissions.sh`.
   - Bổ sung module `check_services.sh` và `check_kernel.sh`.
2. **Xây dựng Module Khắc phục Tự động (Auto-Remediation / Hardening):**
   - Thêm cờ `--fix` cho phép quản trị viên tự động sửa các cấu hình sai (đổi phân quyền file, bật UFW, tắt PermitRootLogin).
3. **Module Xuất Báo cáo Đa định dạng:**
   - Tự động xuất báo cáo đánh giá an ninh dưới dạng Markdown, HTML và JSON.
