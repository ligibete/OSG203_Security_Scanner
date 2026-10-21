# OSG203_Security_Scanner
**Dự án môn học OSG203 - Hệ điều hành (Operating Systems)**  
*Đề tài: Bộ công cụ Tự động hóa Bảo mật Máy chủ (Automated Server Hardening & Security Scanner)*  
*Trường Đại học FPT (FPT University)*

---

## 📌 Giới thiệu Dự án

**OSG203 Security Scanner** là bộ công cụ dòng lệnh được phát triển bằng Bash Shell và Python, chạy trên nền tảng Ubuntu Linux nhằm:
- Tự động hóa rà soát các lỗ hổng cấu hình (misconfigurations) theo tiêu chuẩn bảo mật CIS Ubuntu Linux Benchmark.
- Kiểm tra tài khoản, chính sách mật khẩu, phân quyền tệp tin nhạy cảm và phát hiện leo thang đặc quyền (SUID/SGID).
- Đánh giá trạng thái tường lửa UFW và dịch vụ mạng mở không an toàn.
- Khởi tạo và chuẩn hóa môi trường làm việc bảo mật trên máy ảo VMware.

---

## 🗂️ Cấu trúc Thư mục Dự án

```text
OSG203_Security_Scanner/
├── configs/                  # Bảng tham số và ngưỡng cấu hình dò quét
│   └── audit_rules.conf
├── core/                     # Thư viện hàm dùng chung
│   ├── colors.sh             # Bảng mã màu ANSI & định dạng giao diện
│   ├── logger.sh             # Cơ chế ghi nhật ký hệ thống
│   └── utils.sh              # Các hàm tiện ích (kiểm tra root, OS, phần cứng)
├── docs/                     # Tài liệu thiết kế & quy chuẩn kỹ thuật
│   ├── coding_convention.md  # Quy chuẩn viết mã nguồn
│   ├── git_workflow.md       # Quy trình làm việc nhóm & phân nhánh Git
│   ├── security_audit_scope.md # Đặc tả phạm vi 7 nhóm tiêu chí bảo mật
│   └── phase1_initialization_report.md # Báo cáo nghiệm thu Giai đoạn 1
├── logs/                     # Lưu trữ lịch sử các lần chạy quét
├── scripts/                  # Các module kiểm tra độc lập
│   ├── check_users.sh        # Module 1: Quét tài khoản & xác thực
│   ├── check_ssh.sh          # Module 2: Quét bảo mật dịch vụ SSH
│   ├── check_firewall.sh     # Module 3: Quét tường lửa UFW & cổng mạng
│   └── check_permissions.sh  # Module 4: Quét phân quyền tệp tin & SUID
├── setup_env.sh              # Tự động cài đặt gói phụ trợ & phân quyền (Task 1.5 & 1.6)
├── verify_system.sh          # Tự động đánh giá tính sẵn sàng hệ thống (Task 1.7)
├── main.sh                   # Entrypoint điều phối toàn bộ tiến trình quét
├── .gitignore
└── README.md
```

---

## 🚀 Hướng dẫn Cài đặt & Sử dụng Nhanh

### 1. Thiết lập Môi trường & Gói Phụ trợ (Task 1.5 & 1.6)
Chạy script cài đặt tự động toàn bộ gói bổ trợ (`open-vm-tools`, `openssh-server`, `ufw`, `auditd`, v.v.) và phân quyền nhóm `osgsec`:
```bash
sudo ./setup_env.sh
```

### 2. Kiểm tra Tính Sẵn sàng của Máy ảo & Hệ điều hành (Task 1.7)
Chạy bộ kiểm tra readiness tự động để xác nhận máy ảo đã đáp ứng đầy đủ tiêu chuẩn môn học:
```bash
./verify_system.sh
```

### 3. Thực thi Bộ Dò quét Bảo mật Toàn diện
```bash
sudo ./main.sh
```
Kết quả và nhật ký quét sẽ hiển thị trực quan trên terminal và tự động lưu vào thư mục `logs/scan_YYYYMMDD.log`.

---

## 👥 Thành viên Thực hiện & Phân công
- **Kho mã nguồn GitHub:** [OSG203_Security_Scanner](https://github.com/ligibete/OSG203_Security_Scanner.git)
- **Quy trình phối hợp:** Chi tiết tại [docs/git_workflow.md](docs/git_workflow.md)
