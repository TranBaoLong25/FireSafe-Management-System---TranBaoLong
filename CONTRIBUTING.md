# Quy tắc làm việc với repo – Nhóm G1.8 FireSafe

Trưởng nhóm (chủ repo): **Trần Bảo Long (TV5)**. Kế hoạch và phân công theo tuần nằm ở sheet *Kế hoạch & phân công theo tuần – FireSafe*.

## 1. Cài git lần đầu (mỗi người làm một lần)

```bash
git config --global user.name  "Họ Tên Đầy Đủ"        # vd: Huỳnh Thúy Hằng
git config --global user.email "mssv@ut.edu.vn"        # email trường, trùng email tài khoản GitHub
git config --global core.autocrlf true                 # Windows: tránh git báo sửa cả file vì xuống dòng
git clone https://github.com/TranBaoLong25/FireSafe-Management-System---TranBaoLong.git
```

Kiểm tra: `git config user.name` phải ra **đúng tên của bạn**, vì commit dùng tên này để chấm phần đóng góp.

## 2. Nhánh

- `main`: luôn chạy được. **Không ai push thẳng vào `main`**, kể cả trưởng nhóm; mọi thay đổi đi qua pull request.
- Mỗi task trong sheet phân công một nhánh, đặt đúng tên ở cột *Nhánh git*:

| Loại | Tiền tố | Ví dụ |
|---|---|---|
| Chức năng mới (BE, FE, DevOps) | `feature/` | `feature/auth-login` |
| Sửa lỗi | `fix/` | `fix/facility` |
| Tài liệu | `docs/` | `docs/incident-gis` |
| Test | `test/` | `test/equipment` |

Tên nhánh viết thường, không dấu, nối bằng gạch ngang.

```bash
git checkout main && git pull           # lấy bản mới nhất
git checkout -b feature/auth-login      # tạo nhánh cho task
# ... làm, commit ...
git push -u origin feature/auth-login   # đẩy lên rồi mở pull request trên GitHub
```

## 3. Commit

Mẫu: `<loại>(<service>): <mô tả ngắn, tiếng Việt>` và mã task ở cuối nếu có.

```
feat(auth): đăng nhập trả access token và refresh token [T5-01]
fix(facility): sửa lỗi lọc theo loại hình cơ sở [T8-05]
docs(incident-gis): mô tả bảng dữ liệu và API [T4-10]
test(equipment): test API lần bảo dưỡng [T5-09]
chore(docker): thêm gateway nginx [T4-02]
```

| Loại | Dùng khi |
|---|---|
| `feat` | thêm chức năng |
| `fix` | sửa lỗi |
| `docs` | tài liệu |
| `test` | thêm, sửa test |
| `refactor` | sửa code nhưng không đổi chức năng |
| `chore` | cấu hình, Docker, CI, thư viện |

`<service>`: `auth`, `facility`, `equipment`, `inspection`, `incident-gis`, `common`, `gateway`, `fe`, `docker`, `ci`.

Mỗi commit làm một việc. Không commit file `.env`, `node_modules/`, `coverage/`, file sao lưu.

## 4. Pull request

1. Tiêu đề PR = mã task + tên task, vd `[T5-01] Đăng nhập, khóa tài khoản`.
2. Điền đủ mẫu PR (tự hiện khi mở PR): làm gì, cách thử, minh chứng (ảnh Swagger/Postman, kết quả `npm test`).
3. Cần **ít nhất 1 người duyệt** (trưởng nhóm hoặc người làm service liên quan) mới được merge.
4. Merge xong thì xóa nhánh và đổi trạng thái task trong sheet thành **Xong**.

## 5. Quy ước code

- Mỗi service một CSDL riêng, không truy cập CSDL của service khác; cần dữ liệu thì gọi API.
- Mật khẩu, khóa bí mật để trong `.env` (chép từ `.env.example`), không ghi vào code.
- Đổi cấu trúc bảng thì sửa cả ERD trên Confluence.
