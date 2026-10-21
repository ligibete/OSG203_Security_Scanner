# QUY TRÌNH LÀM VIỆC NHÓM VÀ QUẢN LÝ MÃ NGUỒN VỚI GIT
**Dự án:** OSG203 Security Scanner  
**Kho mã nguồn:** `https://github.com/ligibete/OSG203_Security_Scanner.git`  
**Nhánh mặc định:** `main`  

---

## 1. Mô hình Phân nhánh (Git Branching Strategy)

Dự án áp dụng mô hình **Gitflow thu gọn** phù hợp cho nhóm học tập và phát triển nhanh:

1. **Nhánh `main`:**
   - Chứa mã nguồn ổn định nhất, sẵn sàng nghiệm thu hoặc báo cáo giảng viên.
   - Không commit trực tiếp lên nhánh `main`. Mọi thay đổi đều phải thông qua Pull Request (PR) từ nhánh `develop` hoặc nhánh tính năng.

2. **Nhánh `develop`:**
   - Nhánh tích hợp mã nguồn chính trong quá trình phát triển giai đoạn (Sprint).
   - Tích hợp code sau khi các thành viên hoàn thành nhánh tính năng.

3. **Các nhánh tính năng (`feature/<ten-tinh-nang>`):**
   - Rẽ nhánh từ `develop`.
   - Mỗi thành viên phụ trách một module cụ thể sẽ tạo nhánh riêng:
     - `feature/check-users`: Quét tài khoản và mật khẩu
     - `feature/check-ssh`: Quét cấu hình SSH
     - `feature/check-firewall`: Quét cấu hình tường lửa UFW
     - `feature/check-permissions`: Quét phân quyền tệp tin hệ thống
     - `feature/reporting`: Xây dựng module xuất báo cáo tổng hợp

4. **Các nhánh sửa lỗi (`bugfix/<ten-loi>` hoặc `hotfix/<ten-loi>`):**
   - Xử lý các lỗi phát sinh trong quá trình chạy thử nghiệm hoặc kiểm tra tính sẵn sàng.

---

## 2. Quy chuẩn Thông điệp Commit (Conventional Commits)

Mỗi commit message phải tuân thủ định dạng chuẩn quốc tế:
```
<type>(<scope>): <mô tả ngắn gọn bằng tiếng Anh hoặc tiếng Việt>
```

### Các tiền tố `<type>` được chấp nhận:
- `feat`: Tính năng mới (Ví dụ: `feat(ssh): add ssh root login detection`)
- `fix`: Sửa lỗi (Ví dụ: `fix(firewall): fix ufw status parsing regex`)
- `docs`: Cập nhật tài liệu (Ví dụ: `docs: update security audit scope documentation`)
- `style`: Định dạng code, dấu cách, khoảng trắng (không thay đổi logic)
- `refactor`: Tái cấu trúc code (không thêm tính năng, không sửa lỗi)
- `chore`: Công việc hỗ trợ, cấu hình môi trường, `.gitignore`
- `test`: Viết hoặc sửa script kiểm thử

---

## 3. Quy trình Làm việc Hàng ngày (Daily Workflow)

```bash
# 1. Cập nhật mã nguồn mới nhất từ nhánh chính
git checkout develop
git pull origin develop

# 2. Tạo nhánh làm việc cho module được giao
git checkout -b feature/check-firewall

# 3. Viết code, kiểm tra chạy thử nghiệm trên máy ảo Ubuntu
chmod +x scripts/check_firewall.sh
./scripts/check_firewall.sh

# 4. Thêm file và commit theo chuẩn
git status
git add scripts/check_firewall.sh docs/
git commit -m "feat(firewall): implement UFW rule audit script"

# 5. Đẩy nhánh lên GitHub
git push -u origin feature/check-firewall

# 6. Tạo Pull Request trên GitHub để Trưởng nhóm Review & Merge vào develop
```

---

## 4. Phân công Vai trò trong Nhóm Dự án

| Vai trò | Trách nhiệm chính |
| :--- | :--- |
| **Team Leader** | Quản lý kho Git, duyệt Pull Request, phân chia task, chuẩn hóa cấu trúc dự án |
| **Member 1** | Phụ trách Module Quét Tài khoản & Mật khẩu (`check_users.sh`) |
| **Member 2** | Phụ trách Module Quét Dịch vụ Mạng & SSH (`check_ssh.sh`, `check_firewall.sh`) |
| **Member 3** | Phụ trách Module Quét Phân quyền Tệp tin & SUID (`check_permissions.sh`) |
| **Member 4** | Phụ trách Module Giám sát Hệ thống & Tích hợp (`main.sh`, Báo cáo) |
