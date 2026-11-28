# pccc-service-auth – bảng dữ liệu và API (bản 1.1)

Task **T4-12** · Người làm: Huỳnh Thúy Hằng (TV1) · Checklist 1.1: **#8** (thiết kế CSDL)
Phạm vi: **UC01** Quản trị hệ thống và người dùng – đăng nhập, token, khóa tài khoản, người dùng, đơn vị, vai trò, quyền, nhật ký.

| | |
|---|---|
| Cổng service | 3001 (qua gateway: `http://localhost:8088/api/v1/...`) |
| CSDL | `pccc_auth`, PostgreSQL 16 (cổng máy 5433) |
| Khởi tạo CSDL | `db/init/01_schema.sql` → `02_seed.sql` (bản 1.1 thêm migration `001_password_resets.sql`, `09_demo.sql`) |
| Vai trò với service khác | Cấp JWT cho cả hệ thống; 4 service kia chỉ kiểm tra chữ ký token bằng `JWT_SECRET` dùng chung, không gọi auth mỗi request |

## 1. Cách chạy thử

```bash
cd firesafe-boilerplate
cp .env.example .env
docker compose up -d --build
docker compose exec -e ADMIN_PASSWORD='Admin@12345' auth npm run seed:admin
# đăng nhập
curl -X POST localhost:8088/api/v1/auth/login -H 'Content-Type: application/json' \
     -d '{"username":"admin","password":"Admin@12345"}'
# thông tin người đang đăng nhập (thay <TOKEN> bằng accessToken vừa nhận)
curl localhost:8088/api/v1/auth/me -H 'Authorization: Bearer <TOKEN>'
# xem bảng
docker compose exec auth-db psql -U postgres -d pccc_auth -c '\dt'
```

Thử khóa tài khoản: đăng nhập sai mật khẩu 5 lần, lần sau trả **423 LOCKED** trong 15 phút.

## 2. Bảng dữ liệu (8 bảng; bản 1.1 thêm 1)

| Bảng | Ý nghĩa | Cột chính | Khóa / liên kết | Ràng buộc |
|---|---|---|---|---|
| `units` | Đơn vị (Công an tỉnh, phòng, đội...) dạng cây | `code` (duy nhất), `name`, `parent_id`, `level`, `province_code`, `district_code`, `ward_code` | `parent_id` → `units` (đơn vị cha) | không tự làm cha của chính mình |
| `users` | Tài khoản | `username` (duy nhất), `password_hash` (bcrypt), `full_name`, `email` (duy nhất), `phone`, `id_number`, `unit_id`, `last_login_at`, `failed_login_count`, `locked_until` | `unit_id` → `units` | `status`: ACTIVE, INACTIVE, LOCKED |
| `roles` | Vai trò | `code` (duy nhất), `name`, `description`, `is_system` | | |
| `permissions` | Quyền | `code` dạng `<module>:<action>` (duy nhất), `name`, `module`, `action` | | |
| `user_roles` | Gán vai trò cho người dùng, **có phạm vi** | `user_id`, `role_id`, `scope_type`, `scope_id`, `assigned_by`, `assigned_at` | → `users`, `roles` (xóa theo) | không trùng (người, vai trò, phạm vi) |
| `role_permissions` | Quyền của vai trò | `role_id`, `permission_id` | khóa chính ghép 2 cột | |
| `refresh_tokens` | Phiên đăng nhập | `user_id`, `token_hash` (chỉ lưu bản băm), `expires_at`, `revoked`, `revoked_at`, `device_info`, `ip_address` | → `users` | |
| `audit_logs` | Nhật ký thao tác | `user_id`, `action`, `resource_type`, `resource_id`, `old_value`, `new_value`, `ip_address`, `request_id`, `performed_at` | → `users` (xóa người thì để NULL) | chỉ đọc qua API |
| `password_resets` *(1.1)* | Link quên mật khẩu, dùng 1 lần | `user_id`, `token_hash` (SHA-256), `expires_at`, `used_at`, `requested_ip` | → `users` | |

```
units 1───n units (cha – con)
units 1───n users 1───n user_roles n───1 roles 1───n role_permissions n───1 permissions
users 1───n refresh_tokens · audit_logs · password_resets
```

`user_roles.scope_type/scope_id` dùng để giới hạn phạm vi: vd chủ cơ sở có `scope_type = 'FACILITY'`, `scope_id` = mã cơ sở của họ.

### Dữ liệu có sẵn (`02_seed.sql`)

| Vai trò | Quyền mặc định |
|---|---|
| ADMIN | tất cả quyền |
| MANAGER | đọc tất cả; `inspection:approve`, `report:write` |
| INSPECTOR | đọc tất cả; ghi kiểm tra, vi phạm, sự cố, GIS, điều kiện an toàn, báo cáo |
| FACILITY_OWNER | xem cơ sở, hồ sơ, thiết bị, tự kiểm tra, tồn tại, vi phạm, thông báo; ghi hồ sơ, thiết bị, điều kiện an toàn, tự kiểm tra, khắc phục |
| VIEWER | chỉ đọc |

43 quyền, chia theo nhóm: unit, user, role, permission, facility, dossier, equipment, safety, checklist, self_inspection, inspection, finding, violation, penalty, remediation, incident, gis, resource, report, notification, alert_rule (mỗi nhóm read / write) và `inspection:approve`.

## 3. API (`/api/v1`)

### Có sẵn trong mã khung

| Method | Đường dẫn | Quyền | Ghi chú |
|---|---|---|---|
| POST | `/auth/login` `{username, password}` | công khai | trả `accessToken` (15 phút), `refreshToken` (7 ngày), `roles`, `permissions`; sai 5 lần khóa 15 phút (423) |
| POST | `/auth/refresh` `{refreshToken}` | công khai | cấp token mới |
| POST | `/auth/logout` | đăng nhập | thu hồi refresh token |
| GET | `/auth/me` | đăng nhập | thông tin, vai trò, quyền của mình |
| GET, POST | `/users` | user:read / user:write | không bao giờ trả `password_hash`; lọc: unit_id, status |
| GET, PUT, DELETE | `/users/:id` | user | |
| POST | `/users/:id/roles` `{role_id, scope_type, scope_id}` | user:write | gán vai trò, ghi nhật ký ASSIGN_ROLE |
| DELETE | `/users/:id/roles/:userRoleId` | user:write | gỡ vai trò |
| CRUD | `/units` | unit | lọc: parent_id, level, province_code, district_code |
| CRUD | `/roles` | role | |
| GET, POST, DELETE | `/roles/:id/permissions`, `/roles/:id/permissions/:pid` | role | xem, gán, gỡ quyền của vai trò |
| CRUD | `/permissions` | permission | lọc: module |
| GET | `/audit-logs`, `/audit-logs/:id` | user:read | chỉ đọc; lọc: user_id, action, resource_type |

### Bản 1.1 làm thêm (để làm lại ở tuần 5–7)

| Method | Đường dẫn | Việc | Task |
|---|---|---|---|
| POST | `/auth/change-password` | đổi mật khẩu, các thiết bị khác phải đăng nhập lại | T6-02 |
| POST | `/auth/forgot-password`, `/auth/reset-password` | link đặt lại mật khẩu 1 lần, hết hạn 30 phút | T6-02 |
| PUT | `/users/:id/password` | Admin đặt mật khẩu mới, thu hồi mọi phiên | T6-02 |
| — | token mang `scopes` | chủ cơ sở chỉ thấy dữ liệu cơ sở của mình ở các service khác | T6-02 |
| GET | `/internal/recipients?roles=&facility_id=` | service khác hỏi ai nhận cảnh báo (gateway không mở ra ngoài) | T6-14 |
| — | kiểm tra độ mạnh mật khẩu khi tạo người dùng | lỗi `WEAK_PASSWORD` | T5-03 |

## 4. Nhận xét khi đọc code

- Số lần sai (5) và thời gian khóa (15 phút) đang **viết cứng** trong `auth.service.js`; đặc tả UC01.08 yêu cầu cấu hình được → T6-16.
- Chưa có **danh mục dùng chung** (loại, mức độ sự cố, địa bàn...) theo UC01.06 → T5-16.
- Chưa chặn: xóa / hạ quyền **Admin cuối cùng**, Admin tự khóa mình, xóa vai trò đang được gán → T6-16.
- Xóa người dùng đang là xóa thật (`DELETE`); đặc tả yêu cầu tài khoản đã có dữ liệu chỉ được khóa.
- Chi tiết luồng và câu hỏi: `docs/dac-ta-auth.md`.
