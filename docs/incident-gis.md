# pccc-service-incident-gis – bảng dữ liệu và API (bản 1.1)

Task **T4-10** · Người làm: Trần Bảo Long (TV5) · Checklist 1.1: **#8** (thiết kế CSDL)
Phạm vi: **UC07** tồn tại – vi phạm – xử phạt – khắc phục · **UC08** sự cố cháy, nổ, CNCH · **UC09** bản đồ GIS · **UC10** báo cáo, thông báo, cảnh báo.

| | |
|---|---|
| Cổng service | 3005 (qua gateway: `http://localhost:8088/api/v1/...`) |
| CSDL | `pccc_incident_gis`, PostgreSQL 16 + **PostGIS 3.4** (cổng máy 5437) |
| Khởi tạo CSDL | `db/init/01_schema.sql` → `02_seed.sql` → `03_uc10_report_notification.sql` → `04_seed_uc10.sql` (bản 1.1 thêm `05_runtime.sql`, `09_demo.sql`) |
| Liên kết service khác | Cột *Ref* (`facility_id`, `unit_id`, `user_id`...) **chỉ lưu ID, không có khóa ngoại** vì nằm ở CSDL khác |

## 1. Cách chạy thử

```bash
cd firesafe-boilerplate
cp .env.example .env
docker compose up -d --build incident-gis gateway auth
docker compose exec -e ADMIN_PASSWORD='Admin@12345' auth npm run seed:admin
# đăng nhập lấy token
curl -X POST localhost:8088/api/v1/auth/login -H 'Content-Type: application/json' \
     -d '{"username":"admin","password":"Admin@12345"}'
# gọi thử (thay <TOKEN>)
curl localhost:8088/api/v1/gis/layers -H 'Authorization: Bearer <TOKEN>'
# xem bảng
docker compose exec incident-gis-db psql -U postgres -d pccc_incident_gis -c '\dt'
```

## 2. Bảng dữ liệu (14 bảng)

### UC07 – Tồn tại, vi phạm, xử phạt, khắc phục

| Bảng | Ý nghĩa | Cột chính | Khóa / liên kết | Giá trị cho phép |
|---|---|---|---|---|
| `findings` | Tồn tại phát hiện khi kiểm tra | `facility_id`, `source_type`, `source_id`, `description`, `severity`, `recommendation`, `detected_at`, `evidence_urls` | `facility_id` → facility (Ref); `source_id` → phiếu kiểm tra ở inspection (Ref) | `source_type`: SELF_INSPECTION, OFFICIAL_INSPECTION · `severity`: NHẸ, TRUNG_BÌNH, NGHIÊM_TRỌNG · `status`: MỚI, ĐANG_XỬ_LÝ, ĐÃ_KHẮC_PHỤC, QUÁ_HẠN |
| `violations` | Hành vi vi phạm | `code` (duy nhất), `facility_id`, `finding_id`, `violation_type`, `legal_basis`, `severity`, `detected_date` | `finding_id` → `findings` (FK, xóa tồn tại thì để NULL) | `status`: MỚI, ĐANG_XỬ_LÝ, ĐÃ_XỬ_LÝ, QUÁ_HẠN |
| `administrative_penalties` | Quyết định xử phạt hành chính | `decision_no` (duy nhất), `decision_date`, `penalty_form`, `fine_amount` ≥ 0, `payment_status`, `file_url` | `violation_id` → `violations` (FK, xóa theo) | `penalty_form`: CẢNH_CÁO, PHẠT_TIỀN, ĐÌNH_CHỈ · `payment_status`: CHƯA_NỘP, ĐÃ_NỘP, QUÁ_HẠN |
| `remediations` | Kế hoạch và kết quả khắc phục | `action_plan`, `responsible_user_id`, `planned_date`, `completed_date`, `result_description`, `evidence_urls`, `verified_by`, `verified_at` | `finding_id` → `findings` (FK, xóa theo); `violation_id` → `violations` | `status`: CHỜ, ĐANG_THỰC_HIỆN, CHỜ_XÁC_NHẬN, HOÀN_THÀNH |

### UC08 – Sự cố cháy, nổ, CNCH

| Bảng | Ý nghĩa | Cột chính | Khóa / liên kết | Giá trị cho phép |
|---|---|---|---|---|
| `incidents` | Sự cố | `code` (duy nhất), `incident_type`, `facility_id` (có thể trống), `occurred_at`, `reported_by`, `address`, `latitude`, `longitude`, `cause`, `burned_area`, `death_count`, `injury_count`, `rescued_count`, `property_damage`, `level` | `facility_id`, `reported_by` (Ref) | `incident_type`: CHÁY, NỔ, SỰ_CỐ_KHÁC, CNCH · `level`: NHỎ, TRUNG_BÌNH, LỚN, RẤT_LỚN · `status`: TIẾP_NHẬN, ĐANG_XỬ_LÝ, ĐÃ_DẬP_TẮT, ĐÃ_KẾT_LUẬN |
| `incident_responses` | Lực lượng được điều đến | `unit_id`, `vehicle_count`, `personnel_count`, `arrived_at`, `extinguished_at` | `incident_id` → `incidents` (FK, xóa theo); `unit_id` → auth.units (Ref) | |
| `incident_investigations` | Điều tra, kết luận nguyên nhân | `investigator_id`, `conclusion`, `responsibility`, `report_url`, `concluded_at` | `incident_id` → `incidents` | |
| `incident_attachments` | Ảnh, tài liệu sự cố | `file_url`, `file_type`, `description`, `uploaded_by` | `incident_id` → `incidents` | |

### UC09 – Bản đồ GIS

| Bảng | Ý nghĩa | Cột chính | Khóa / liên kết | Giá trị cho phép |
|---|---|---|---|---|
| `gis_layers` | Lớp bản đồ | `code` (duy nhất), `name`, `layer_type`, `source`, `style_config`, `is_visible_default`, `min_role` | | `layer_type`: POINT, LINE, POLYGON · `source`: FACILITY, EQUIPMENT, INCIDENT, CUSTOM |
| `gis_features` | Đối tượng trên bản đồ | `ref_type`, `ref_id`, `name`, **`geometry` (PostGIS, SRID 4326)**, `properties` | `layer_id` → `gis_layers`; chỉ mục GIST trên `geometry` | |
| `firefighting_resources` | Đội PCCC, trụ nước, bể nước, xe | `resource_type`, `name`, `unit_id`, `latitude`, `longitude`, `capacity` | `unit_id` (Ref) | `resource_type`: ĐỘI_PCCC, TRỤ_NƯỚC, BỂ_NƯỚC, XE_CHỮA_CHÁY · `status`: SẴN_SÀNG, ĐANG_SỬ_DỤNG, HỎNG |

Dữ liệu có sẵn: 4 lớp bản đồ `FACILITY`, `INCIDENT`, `HYDRANT`, `FIRE_UNIT`.

### UC10 – Báo cáo, thông báo, cảnh báo

| Bảng | Ý nghĩa | Cột chính | Giá trị cho phép |
|---|---|---|---|
| `reports` | Báo cáo đã lập | `code`, `name`, `report_type`, `period_type`, `from_date`, `to_date`, `scope_unit_id`, `result_data`, `file_url`, `generated_by` | `report_type`: THỐNG_KÊ_CƠ_SỞ, KIỂM_TRA, VI_PHẠM, SỰ_CỐ, TỔNG_HỢP · `period_type`: THÁNG, QUÝ, NĂM, TÙY_CHỌN |
| `notifications` | Thông báo gửi người dùng | `recipient_user_id`, `title`, `content`, `notification_type`, `ref_type`, `ref_id`, `channel`, `is_read`, `read_at`, `sent_at` | `notification_type`: HẾT_HẠN_TÀI_LIỆU, TỚI_HẠN_KIỂM_TRA, VI_PHẠM_QUÁ_HẠN, SỰ_CỐ, HỆ_THỐNG · `channel`: IN_APP, EMAIL, SMS, PUSH |
| `alert_rules` | Quy tắc cảnh báo | `code`, `name`, `trigger_type`, `days_before`, `target_roles`, `channels`, `is_active` | |

Dữ liệu có sẵn: 5 quy tắc `TAI_LIEU_SAP_HET_HAN` (30 ngày), `BAO_DUONG_TOI_HAN` (7), `KIEM_TRA_TOI_HAN` (7), `KHAC_PHUC_QUA_HAN`, `SU_CO_MOI`.

Bản 1.1 thêm bảng `audit_logs` (nhật ký thao tác, mục #39).

### Sơ đồ quan hệ trong CSDL

```
findings 1───n violations 1───n administrative_penalties
   │               │
   └──1───n remediations n───1┘      (remediation gắn tồn tại, có thể gắn thêm vi phạm)

incidents 1───n incident_responses / incident_investigations / incident_attachments
gis_layers 1───n gis_features            firefighting_resources (độc lập)
reports · notifications · alert_rules    (độc lập)
```

## 3. API (`/api/v1`, mọi API cần token)

Danh sách có phân trang `?page=1&limit=20` và lọc theo cột, vd `?status=MỚI`. Quyền dạng `<nhóm>:read` / `<nhóm>:write` (ADMIN bỏ qua).

### Có sẵn trong mã khung

| Method | Đường dẫn | Quyền | Ghi chú |
|---|---|---|---|
| GET, POST | `/findings` | finding | lọc: facility_id, status, severity, source_type |
| GET, PUT, DELETE | `/findings/:id` | finding | |
| GET, POST | `/violations` | violation | lọc: facility_id, finding_id, status, severity |
| GET, PUT, DELETE | `/violations/:id` | violation | |
| GET, POST | `/violations/:id/penalties` | penalty | xử phạt của một vi phạm |
| CRUD | `/penalties` | penalty | lọc: violation_id, payment_status, penalty_form |
| CRUD | `/remediations` | remediation | lọc: finding_id, violation_id, status, responsible_user_id |
| CRUD | `/incidents` | incident | lọc: incident_type, facility_id, status, level |
| CRUD | `/incidents/:id/responses` · `/investigations` · `/attachments` | incident | |
| CRUD | `/gis/layers` | gis | |
| GET | `/gis/layers/:id/features?bbox=minLng,minLat,maxLng,maxLat` | gis:read | trả **GeoJSON FeatureCollection** |
| GET, POST, DELETE | `/gis/features`, `/gis/features/:id` | gis | `geometry` gửi dạng GeoJSON |
| CRUD | `/gis/resources` | resource | lọc: resource_type, unit_id, status |

### Bản 1.1 làm thêm (để làm lại ở tuần 5–8)

| Method | Đường dẫn | Việc | Task |
|---|---|---|---|
| POST | `/violations/:id/penalties`, `/penalties` | lập xử phạt → vi phạm MỚI tự sang ĐANG_XỬ_LÝ (1 transaction) | T5-14 |
| POST | `/incidents/:id/responses` | điều lực lượng → sự cố TIẾP_NHẬN tự sang ĐANG_XỬ_LÝ | T5-14 |
| POST | `/remediations/:id/submit` | cơ sở báo đã khắc phục → CHỜ_XÁC_NHẬN | T6-13 |
| PUT | `/remediations/:id/verify` `{approved, note}` | cán bộ xác nhận → HOÀN_THÀNH, tồn tại ĐÃ_KHẮC_PHỤC, vi phạm ĐÃ_XỬ_LÝ; từ chối → ĐANG_THỰC_HIỆN | T6-13 |
| GET, POST, DELETE | `/reports` | lập báo cáo VI_PHẠM / SỰ_CỐ tự đếm theo trạng thái trong khoảng ngày | T8-12 |
| GET | `/notifications/mine?unread=true` · POST `/notifications/:id/read` | thông báo của người đăng nhập | T6-14 |
| CRUD | `/alert-rules` | quy tắc cảnh báo | T6-14 |
| POST | `/internal/alerts` · PUT `/internal/gis/sync` | service khác gửi cảnh báo / tọa độ (gateway không mở ra ngoài) | T6-14 |
| — | tác vụ mỗi 60 phút | khắc phục quá hạn → QUÁ_HẠN + cảnh báo; quét sự cố mới; đồng bộ sự cố lên bản đồ | T6-13, T6-14 |

## 4. Nhận xét khi đọc code

- Liên kết sang service khác chỉ bằng ID nên khi hiện danh sách vi phạm phải gọi facility để lấy tên cơ sở.
- Trạng thái trong code khác đặc tả Confluence ở UC07 (đặc tả có 6 trạng thái) và UC08 (thiếu diễn biến, xác nhận thiệt hại, mở lại) – xem `docs/dac-ta-incident-gis.md` mục câu hỏi.
- Bảng UC10 đang nằm chung CSDL incident-gis; cần nhóm chốt có tách Notification Service riêng (UC10.09) hay không.
