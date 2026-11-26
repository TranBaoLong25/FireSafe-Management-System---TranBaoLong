# FireSafe Management System – Mã khung (Boilerplate)

Nhóm G1.8 – UTH–Gtel OTS. Node.js 20 + Express + PostgreSQL (PostGIS cho incident-gis), JWT + RBAC.
Mô hình **Database per Service**: mỗi service 1 database riêng; liên kết giữa service là cột "Ref" (chỉ lưu ID, không FK).

## Cấu trúc
```
firesafe/
├─ docker-compose.yml          # 5 service + 5 database
├─ .env.example
├─ pccc-service-auth/          # UC01  (cổng 3001, DB 5433)  – ĐÃ CÓ code + SQL
├─ pccc-service-facility/      #       (cổng 3002, DB 5434)  – khung, SQL chờ model
├─ pccc-service-equipment/     #       (cổng 3003, DB 5435)  – khung, SQL chờ model
├─ pccc-service-inspection/    #       (cổng 3004, DB 5436)  – khung, SQL chờ model
└─ pccc-service-incident-gis/  # UC07-09 (cổng 3005, DB 5437) – ĐÃ CÓ code + SQL
   ├─ db/init/*.sql            # script khởi tạo CSDL (chạy theo thứ tự tên file)
   └─ src/
      ├─ server.js, app.js     # khởi động, middleware chung, /health
      ├─ config/               # env.js, db.js (pool + db.tx cho transaction)
      ├─ middlewares/          # authenticate (JWT), authorize (RBAC), errorHandler
      ├─ utils/crud.js         # sinh CRUD nhanh cho 1 bảng
      ├─ modules/              # nghiệp vụ của service
      └─ routes/index.js       # gắn route
```

## Chạy nhanh (Docker)
```bash
cp .env.example .env            # rồi đổi JWT_SECRET, DB_PASSWORD
docker compose up -d --build    # 5 CSDL + 5 service + gateway (11 container)
docker compose ps               # đợi tất cả "healthy"
curl localhost:8088/health      # gateway
# tạo admin đầu tiên:
docker compose exec -e ADMIN_PASSWORD='Admin@12345' auth npm run seed:admin
curl -X POST localhost:8088/api/v1/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"Admin@12345"}'
```
Mọi API gọi qua gateway `http://localhost:8088/api/v1/...`; cổng riêng 3001–3005 chỉ để gỡ lỗi.
Thiếu `JWT_SECRET` hoặc `DB_PASSWORD` trong `.env` thì compose dừng và báo lỗi.
Script trong `db/init/` chỉ tự chạy **lần đầu** khi volume CSDL còn trống. Muốn chạy lại từ đầu: `docker compose down -v`.

## Chạy tay (không Docker)
```bash
createdb pccc_auth && psql -d pccc_auth -f pccc-service-auth/db/init/01_schema.sql -f pccc-service-auth/db/init/02_seed.sql
cd pccc-service-auth && cp .env.example .env && npm install && npm run dev
```
incident-gis cần cài PostGIS (`CREATE EXTENSION postgis`).

## API đã có
**auth (`/api/v1`)**: `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `GET /auth/me` · `/users` (+ `POST /users/:id/roles`) · `/units` · `/roles` (+ `/roles/:id/permissions`) · `/permissions` · `GET /audit-logs`

**incident-gis (`/api/v1`)**: `/findings` · `/violations` (+ `/violations/:parentId/penalties`) · `/penalties` · `/remediations` · `/incidents` (+ `/:parentId/responses|investigations|attachments`) · `/gis/layers` · `GET /gis/layers/:id/features?bbox=` (GeoJSON) · `/gis/features` · `/gis/resources`

Mỗi route CRUD kiểm tra quyền `<module>:read` / `<module>:write` (ADMIN bỏ qua). Danh sách phân trang: `?page=1&limit=20`, lọc theo cột cho phép `?status=MỚI`.

## Những chỗ là GIẢ ĐỊNH – cần nhóm chốt lại
- Giá trị `users.status`: ACTIVE / INACTIVE / LOCKED; sai mật khẩu 5 lần khóa 15 phút (`auth.service.js`).
- Vai trò & quyền mẫu trong `02_seed.sql` (ADMIN, MANAGER, INSPECTOR, FACILITY_OWNER, VIEWER).
- Các giá trị enum (CHECK) của incident-gis lấy từ bảng mô tả model của nhóm.
- `03_uc10_report_notification.sql` là UC10 (không phải phần của Long) – cùng DB incident-gis, xóa nếu người phụ trách UC10 tự quản lý.
- Cả 5 service dùng chung `JWT_SECRET` (HS256). Sau này có thể nâng cấp RS256 (auth giữ private key).

## Việc còn lại (TODO)
- facility / equipment / inspection: viết `db/init/01_schema.sql` + module khi chốt model.
- `PUT /remediations/:id/verify` (UC07): cập nhật Remediation, Finding, Violation trong 1 transaction `db.tx`.
- Tự đồng bộ trạng thái (Violation → ĐANG_XỬ_LÝ khi có xử phạt; Incident → ĐANG_XỬ_LÝ khi có huy động) như trong sequence diagram.
- Validation đầu vào chi tiết (zod/joi), unit test (jest + supertest), migration tool (node-pg-migrate) nếu muốn.
