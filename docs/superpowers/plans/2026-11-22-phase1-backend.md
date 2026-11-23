# P1. Hoàn thiện Backend – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đủ API cho UC01–UC10 trên 5 service, mỗi API có test, quyền nằm trong seed của auth.

**Architecture:** Giữ nguyên mẫu đang có: bảng thuần CRUD dùng `crudController` + `crudRouter` (`src/utils/crud.js`); luồng nghiệp vụ nhiều bước viết thành service function chạy trong `db.tx`. Cột `status` của các bảng có quy trình KHÔNG nằm trong whitelist CRUD, chỉ đổi qua endpoint hành động (submit/approve/start/complete/sign/verify).

**Tech Stack:** Node.js 20, Express 4, pg 8, PostgreSQL 16 (+PostGIS cho incident-gis), jsonwebtoken. Test: jest 29 + supertest 7 chạy trên DB test thật.

**Spec:** Confluence FSMS 3.3 (sequence), 3.4 (class), 3.5 (ERD); schema `*/db/init/*.sql`; `firesafe-boilerplate/README.md` mục TODO.

## Global Constraints

- Tiền tố API: `/api/v1`. Phân trang `?page=&limit=` (limit tối đa 200), lọc theo cột trong `filterable`.
- Quyền dạng `<module>:read` / `<module>:write`; ADMIN bỏ qua kiểm tra (đã có trong `authorize.js`).
- Lỗi trả `{ error: { code, message } }`; lỗi PostgreSQL map sẵn trong `errorHandler.js` (23505→409, 23503→409, 23514→400, 22P02→400).
- Cột Ref sang service khác chỉ lưu UUID, không gọi chéo service trong P1.
- Thông báo lỗi bằng tiếng Việt, giống `AppError`.
- Không sửa `src/utils/crud.js`, `src/middlewares/*`, `src/config/*` ngoài phạm vi task nêu rõ (5 service đang có bản sao giống nhau).

## Review Focus

1. Gửi phiếu tự kiểm tra khi còn mục chưa trả lời → 400, phiếu vẫn ở `NHÁP` (Task 5).
2. `PUT /self-inspections/:id` gửi `status: "ĐÃ_NỘP"` → trạng thái không đổi, vì `status` không có trong whitelist (Task 5, tương tự Task 6, 7).
3. Duyệt kế hoạch không ở `CHỜ_DUYỆT`, kết thúc kiểm tra chưa bắt đầu, ký biên bản thiếu `signed_file_url` → 409/400, dữ liệu không đổi (Task 6, 7).
4. Lỗi giữa transaction (ví dụ `template_id` không tồn tại khi tạo phiếu) → không để lại bản ghi `inspections` mồ côi (Task 5, 7).
5. Gọi API thiếu quyền (VIEWER gọi POST) → 403; không có token → 401 (Task 1, áp cho mọi router).

---

## Chuẩn bị chung (làm một lần trước Task 1)

Tạo DB test riêng cho từng service, không đụng dữ liệu dev:

```bash
cd firesafe-boilerplate
docker compose up -d auth-db facility-db equipment-db inspection-db incident-gis-db
for s in auth:5433 facility:5434 equipment:5435 inspection:5436 incident_gis:5437; do
  n=${s%%:*}; docker compose exec ${n//_/-}-db createdb -U postgres pccc_${n}_test
done
```

Commit schema 3 service đang chờ:
```bash
git add firesafe-boilerplate/pccc-service-{facility,equipment,inspection}/db/init/01_schema.sql docs/
git commit -m "feat(db): schema facility, equipment, inspection theo ERD 3.5.2-3.5.4"
```

---

### Task 1: Hạ tầng test + API danh mục cơ sở (facility, UC02)

**Files:**
- Modify: `pccc-service-facility/package.json` (devDependencies `jest@^29`, `supertest@^7`; script `"test": "jest --runInBand"`; `"jest": { "setupFiles": ["<rootDir>/tests/setup-env.js"] }`)
- Create: `pccc-service-facility/tests/setup-env.js`, `tests/helpers.js`
- Create: `pccc-service-facility/src/modules/modules.js`
- Modify: `pccc-service-facility/src/routes/index.js`
- Test: `pccc-service-facility/tests/facilities.test.js`

**Interfaces:**
- Produces (copy y nguyên sang 4 service khác ở các task sau, chỉ đổi tên DB):
  - `tests/setup-env.js`: đặt `NODE_ENV=test`, `JWT_SECRET='test-secret-32-ky-tu-xxxxxxxxxxxxxx'`, `DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgres://postgres:postgres@localhost:5434/pccc_facility_test'`.
  - `tests/helpers.js`: `resetDb(): Promise<void>` – `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` rồi chạy lần lượt mọi file `db/init/*.sql` theo tên; `token({ roles = ['ADMIN'], permissions = [], sub = <uuid cố định> } = {}): string` – ký JWT HS256 bằng `JWT_SECRET`; `api(): supertest.SuperTest` – `request(require('../src/app'))`; `afterAll` đóng `db.pool.end()`.
  - Route (quyền `facility`): `/facility-types`, `/organizations`, `/facilities`, lồng `/facilities/:parentId/owners`, `/facilities/:parentId/contacts`, `/facilities/:parentId/fire-fighting-plans`.
  - `facilities` filterable: `facility_type_id, management_unit_id, risk_level, status, province_code, district_code, ward_code`.
  - `src/config/db.js`: thêm `require('pg').types.setTypeParser(1082, (v) => v)` để cột DATE trả chuỗi `'YYYY-MM-DD'` (tránh lệch múi giờ ở test và frontend). Làm giống vậy ở task đầu tiên của mỗi service.

- [ ] **Step 1: Viết test hỏng** trong `tests/facilities.test.js`:
  - `POST /api/v1/facility-types` `{code:'NHA_TRO',name:'Nhà trọ',default_risk_level:'CAO'}` → 201.
  - `POST /api/v1/facilities` với `facility_type_id` vừa tạo, `code:'CS001'`, `name:'Nhà trọ A'` → 201, `body.data.status === 'HOẠT_ĐỘNG'`.
  - Tạo lại `code:'CS001'` → 409.
  - `GET /api/v1/facilities?status=HOẠT_ĐỘNG` → `meta.total === 1`.
  - `POST /api/v1/facilities/:id/contacts` hai lần với `is_primary:true` → lần 2 trả 409.
  - Không token → 401; token `{roles:['VIEWER'],permissions:['facility:read']}` gọi POST → 403, gọi GET → 200.
- [ ] **Step 2:** `npm install && npm test` → FAIL (404 vì chưa có route).
- [ ] **Step 3:** Viết `modules.js` (một `crudController` cho mỗi bảng, con dùng `scope: req => ({ facility_id: req.params.parentId })` như `incident-gis/src/modules/modules.js`) và gắn route trong `routes/index.js` theo mẫu `incidents.use('/:parentId/...')`. `created_by`/`updated_by` không nằm trong whitelist.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(facility): API danh mục cơ sở UC02 + hạ tầng test`.

---

### Task 2: Hồ sơ và tài liệu PCCC (facility, UC03)

**Files:**
- Modify: `pccc-service-facility/src/modules/modules.js`, `src/routes/index.js`
- Create: `pccc-service-facility/src/modules/documents.service.js`
- Test: `pccc-service-facility/tests/dossiers.test.js`

**Interfaces:**
- Consumes: helpers Task 1.
- Produces (quyền `dossier`): `/document-types`, `/dossiers` (+ lồng `/dossiers/:parentId/documents`), `/documents` (CRUD, whitelist không gồm `version`, `file_url`), `GET /documents/:parentId/versions`, `POST /documents/:id/versions`.
- `addVersion(documentId: uuid, { file_url, change_note }, userId: uuid) -> documentVersion` trong `db.tx`: `version_no = documents.version + 1`, insert `document_versions`, update `documents.version`, `documents.file_url`, `uploaded_by`, `uploaded_at = now()`.
- Khi tạo document có `file_url`: tự insert `document_versions` với `version_no = 1` (cùng transaction).

- [ ] **Step 1: Test hỏng:**
  - Tạo dossier `dossier_no:'HS001'` → `status==='CHƯA_ĐẦY_ĐỦ'`, `completeness_percent==='0.00'`.
  - Tạo document có `file_url:'a.pdf'` → `GET /documents/:id/versions` có 1 bản, `version_no===1`.
  - `POST /documents/:id/versions {file_url:'b.pdf'}` → 201, `version_no===2`; GET document → `version===2`, `file_url==='b.pdf'`.
  - `PUT /documents/:id {version: 9}` → version vẫn 2.
  - `expiry_date < issue_date` → 400.
- [ ] **Step 2:** `npm test` → FAIL.
- [ ] **Step 3:** Viết `documents.service.js` và route.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(facility): hồ sơ, tài liệu PCCC và phiên bản UC03`.

---

### Task 3: Thiết bị và điều kiện an toàn (equipment, UC04)

**Files:**
- Modify: `pccc-service-equipment/package.json` (như Task 1), `src/routes/index.js`
- Create: `pccc-service-equipment/tests/setup-env.js`, `tests/helpers.js` (copy Task 1, DB `localhost:5435/pccc_equipment_test`)
- Create: `pccc-service-equipment/src/modules/modules.js`, `src/modules/maintenance.service.js`
- Test: `pccc-service-equipment/tests/equipment.test.js`, `tests/safety.test.js`

**Interfaces:**
- Produces quyền `equipment`: `/equipment-types`, `/equipment` (+ lồng `/equipment/:parentId/maintenances`, `/equipment/:parentId/certificates`), `GET /equipment/maintenance-due?before=YYYY-MM-DD[&facility_id=]`.
- Produces quyền `safety`: `/safety-conditions`, `/facility-safety-conditions`, `/water-sources`.
- `createMaintenance(equipmentId, body) -> maintenance` trong `db.tx`: insert; nếu body có `next_due_date` thì update `equipment.next_maintenance_date`; nếu không có mà loại thiết bị có `maintenance_cycle_days` thì `next_maintenance_date = maintenance_date + cycle`. Route POST lồng maintenances dùng hàm này thay cho `ctrl.create`.
- `maintenance-due`: `next_maintenance_date <= before` và `status <> 'THANH_LÝ'`, sắp tăng dần. Thiếu `before` → 400. Route này khai báo TRƯỚC `/equipment/:id`.

- [ ] **Step 1: Test hỏng:**
  - Loại `maintenance_cycle_days:180`; thiết bị mới; POST maintenance `maintenance_date:'2026-11-01'`, không `next_due_date` → GET thiết bị `next_maintenance_date === '2027-04-30'`.
  - POST maintenance có `next_due_date:'2026-12-01'` → thiết bị nhận `2026-12-01`.
  - `GET /equipment/maintenance-due?before=2026-12-31` có thiết bị đó; thiết bị `THANH_LÝ` không có; thiếu `before` → 400.
  - `facility-safety-conditions` trùng `(facility_id, safety_condition_id)` → 409.
  - Token chỉ có `equipment:write` POST `/water-sources` → 403.
- [ ] **Step 2:** `npm install && npm test` → FAIL.
- [ ] **Step 3:** Viết modules, service, route.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(equipment): API thiết bị, bảo dưỡng, điều kiện an toàn UC04`.

---

### Task 4: Mẫu phiếu và lõi kiểm tra dùng chung (inspection)

**Files:**
- Modify: `pccc-service-inspection/package.json`, `src/routes/index.js`
- Create: `tests/setup-env.js`, `tests/helpers.js` (DB `localhost:5436/pccc_inspection_test`)
- Create: `pccc-service-inspection/src/modules/modules.js`, `src/modules/inspection.core.js`
- Test: `pccc-service-inspection/tests/core.test.js`

**Interfaces:**
- Produces quyền `checklist`: `/templates` (+ lồng `/templates/:parentId/items`).
- `inspection.core.js` (Task 5, 7 dùng):
  - `createInspection(client, { kind: 'SELF_INSPECTION'|'OFFICIAL_INSPECTION', facility_id, inspection_date }) -> { inspection_id }`
  - `saveResults(client, inspectionId, items: [{ template_item_id, result, finding?, recommendation?, evidence_urls? }]) -> number` – upsert theo `(inspection_id, template_item_id)` (`ON CONFLICT ... DO UPDATE`).
  - `computeOverall(client, inspectionId, templateId) -> 'ĐẠT'|'KHÔNG_ĐẠT'|'ĐẠT_CÓ_KIẾN_NGHỊ'` – ném `AppError.badRequest('Còn N mục chưa trả lời')` nếu số mục của template > số kết quả có `result` khác NULL. Có mục `is_critical` bị `KHÔNG_ĐẠT` → `KHÔNG_ĐẠT`; có mục thường `KHÔNG_ĐẠT` → `ĐẠT_CÓ_KIẾN_NGHỊ`; còn lại `ĐẠT`.
  - `finishInspection(client, inspectionId, overall) -> void` – `inspections.overall_result = overall, status = 'HOÀN_THÀNH'`.

- [ ] **Step 1: Test hỏng** (gọi thẳng hàm với `db.tx`): template 3 mục (1 critical):
  - lưu 2 kết quả → `computeOverall` ném lỗi chứa `'Còn 1 mục'`.
  - đủ 3, mục thường KHÔNG_ĐẠT → `'ĐẠT_CÓ_KIẾN_NGHỊ'`; mục critical KHÔNG_ĐẠT → `'KHÔNG_ĐẠT'`; tất cả ĐẠT → `'ĐẠT'`.
  - `saveResults` gọi 2 lần cùng item → vẫn 1 dòng, giá trị mới.
  - API: `POST /templates/:id/items` trùng `order_no` → 409.
- [ ] **Step 2:** `npm install && npm test` → FAIL.
- [ ] **Step 3:** Viết code.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(inspection): mẫu phiếu kiểm tra và lõi tính kết quả`.

---

### Task 5: Tự kiểm tra của cơ sở (inspection, UC05)

**Files:**
- Create: `pccc-service-inspection/src/modules/self.routes.js`
- Modify: `src/routes/index.js`
- Test: `pccc-service-inspection/tests/self-inspection.test.js`

**Interfaces:**
- Consumes: `createInspection`, `saveResults`, `computeOverall`, `finishInspection` (Task 4).
- Produces quyền `self_inspection`:
  - `GET /self-inspections`, `GET /self-inspections/:id` (crud, filterable `facility_id, status, template_id, period`); `GET /:id` trả thêm `results: []`.
  - `POST /self-inspections` body `{ template_id, code, facility_id, inspection_date, period?, note? }` → tạo `inspections` + `self_inspections` trong 1 tx, `inspector_user_id = req.user.id`.
  - `PUT /self-inspections/:id` whitelist `inspection_date, period, note` (chỉ khi `NHÁP`, ngược lại 409).
  - `PUT /self-inspections/:id/results` body `{ items: [...] }` (chỉ khi `NHÁP`).
  - `POST /self-inspections/:id/submit` → chỉ từ `NHÁP`; tính overall; `status='ĐÃ_NỘP'`, `submitted_at=now()`, `overall_result`; gọi `finishInspection`.
  - `DELETE` không mở.

- [ ] **Step 1: Test hỏng:**
  - Tạo phiếu → 201, `status==='NHÁP'`; DB có đúng 1 dòng `inspections` kind `SELF_INSPECTION`.
  - Tạo với `template_id` không tồn tại → 409 và bảng `inspections` vẫn 0 dòng.
  - Submit khi thiếu mục → 400, status vẫn `NHÁP`.
  - Lưu đủ kết quả, submit → 200, `status==='ĐÃ_NỘP'`, `submitted_at` khác null; `inspections.status==='HOÀN_THÀNH'`.
  - Submit lần 2 → 409; `PUT /:id/results` sau khi nộp → 409.
  - `PUT /:id {status:'ĐÃ_TIẾP_NHẬN', note:'x'}` khi NHÁP → `note==='x'`, status vẫn `NHÁP`.
- [ ] **Step 2:** `npm test` → FAIL.
- [ ] **Step 3:** Viết `self.routes.js`.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(inspection): luồng tự kiểm tra UC05`.

---

### Task 6: Kế hoạch kiểm tra (inspection, UC06 phần 1)

**Files:**
- Create: `pccc-service-inspection/src/modules/plan.routes.js`
- Modify: `src/routes/index.js`
- Test: `pccc-service-inspection/tests/plan.test.js`

**Interfaces:**
- Produces quyền `inspection`: `/plans` CRUD (whitelist không có `status, approved_by, approved_at`), lồng `/plans/:parentId/facilities` (whitelist không có `status`).
- `POST /plans/:id/submit` (`inspection:write`): `NHÁP` → `CHỜ_DUYỆT`; kế hoạch chưa có cơ sở nào → 400.
- `POST /plans/:id/approve` (quyền `inspection:approve`): `CHỜ_DUYỆT` → `ĐÃ_DUYỆT`, `approved_by=req.user.id`, `approved_at=now()`. Trạng thái khác → 409.
- `POST /plans/:id/cancel` (`inspection:approve`): từ `NHÁP|CHỜ_DUYỆT` → `HỦY`.
- Chuyển trạng thái viết bằng một câu `UPDATE ... WHERE plan_id=$1 AND status = ANY($2) RETURNING *`; 0 dòng → kiểm tra tồn tại để trả 404 hay 409.

- [ ] **Step 1: Test hỏng:** submit kế hoạch rỗng → 400; thêm 1 cơ sở, submit → `CHỜ_DUYỆT`; token chỉ `inspection:write` gọi approve → 403; token `inspection:approve` approve → `ĐÃ_DUYỆT` và `approved_by` = sub của token; approve lần 2 → 409; `year: 1999` → 400; `quarter: 5` → 400.
- [ ] **Step 2:** `npm test` → FAIL.
- [ ] **Step 3:** Viết `plan.routes.js`.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(inspection): kế hoạch kiểm tra và phê duyệt UC06`.

---

### Task 7: Kiểm tra của cơ quan Công an, đoàn kiểm tra, biên bản (inspection, UC06 phần 2)

**Files:**
- Create: `pccc-service-inspection/src/modules/official.routes.js`
- Modify: `src/routes/index.js`
- Test: `pccc-service-inspection/tests/official.test.js`

**Interfaces:**
- Consumes: Task 4 core; bảng plan Task 6.
- Produces quyền `inspection`:
  - `POST /official-inspections` body `{ code, facility_id, inspection_type, plan_id?, decision_no?, decision_date?, scheduled_date?, lead_inspector_id?, management_unit_id? }` – tạo `inspections`(OFFICIAL) + `official_inspections` trong 1 tx. Có `plan_id` thì kế hoạch phải `ĐÃ_DUYỆT` và chứa `facility_id`, ngược lại 409.
  - `GET` list/get (filterable `facility_id, plan_id, status, inspection_type, lead_inspector_id`), `PUT` whitelist không có `status, start_time, end_time, overall_result`.
  - Lồng `/official-inspections/:parentId/members` (CRUD), `/official-inspections/:parentId/reports` (list/get/create/update; whitelist không có `status`).
  - `POST /official-inspections/:id/start`: `CHỜ_KIỂM_TRA` → `ĐANG_KIỂM_TRA`, `start_time=now()`.
  - `PUT /official-inspections/:id/results` body `{ items }` – chỉ khi `ĐANG_KIỂM_TRA`.
  - `POST /official-inspections/:id/complete` body `{ template_id }` (mẫu phiếu OFFICIAL đã dùng, để `computeOverall` đếm đủ mục): `ĐANG_KIỂM_TRA` → `HOÀN_THÀNH`, `end_time=now()`, `overall_result=computeOverall(...)`, `finishInspection`; có `plan_id` thì `inspection_plan_facilities.status='ĐÃ_KIỂM_TRA'` cho cặp (plan, facility). Tất cả trong 1 tx.
  - `POST /reports/:id/sign`: `NHÁP` → `ĐÃ_KÝ`; `signed_file_url` rỗng → 400.

- [ ] **Step 1: Test hỏng:**
  - Tạo với kế hoạch chưa duyệt → 409, `inspections` 0 dòng.
  - Luồng đầy đủ: kế hoạch duyệt có CS → tạo → start → results → complete → `status==='HOÀN_THÀNH'`, `end_time >= start_time`, dòng plan_facility `ĐÃ_KIỂM_TRA`.
  - Complete khi chưa start → 409.
  - Thêm cùng `user_id` 2 lần vào đoàn → 409.
  - Ký biên bản thiếu `signed_file_url` → 400; có → `ĐÃ_KÝ`; ký lại → 409.
- [ ] **Step 2:** `npm test` → FAIL.
- [ ] **Step 3:** Viết `official.routes.js`.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(inspection): kiểm tra của cơ quan Công an, đoàn kiểm tra, biên bản UC06`.

---

### Task 8: Xác nhận khắc phục và đồng bộ trạng thái (incident-gis, UC07–UC08)

**Files:**
- Modify: `pccc-service-incident-gis/package.json`, `src/routes/index.js`, `src/modules/modules.js` (bỏ `status`, `verified_by`, `verified_at` khỏi whitelist `remediations`)
- Create: `tests/setup-env.js`, `tests/helpers.js` (DB `localhost:5437/pccc_incident_gis_test`), `src/modules/workflow.service.js`
- Test: `pccc-service-incident-gis/tests/workflow.test.js`

**Interfaces:**
- `PUT /remediations/:id/verify` (quyền `remediation:write`) body `{ approved: boolean, note? }`:
  - Chỉ từ `CHỜ_XÁC_NHẬN`, ngược lại 409.
  - `approved=true`: remediation `HOÀN_THÀNH`, `verified_by`, `verified_at`; finding → `ĐÃ_KHẮC_PHỤC`; nếu có violation → `ĐÃ_XỬ_LÝ`. Một tx.
  - `approved=false`: remediation về `ĐANG_THỰC_HIỆN`, ghi `note` vào `result_description`.
- `POST /remediations/:id/submit`: `CHỜ|ĐANG_THỰC_HIỆN` → `CHỜ_XÁC_NHẬN`, `completed_date = CURRENT_DATE`.
- Đồng bộ (thay `create` của route lồng):
  - Tạo penalty cho violation đang `MỚI` → violation `ĐANG_XỬ_LÝ` (cùng tx).
  - Tạo incident response cho incident đang `TIẾP_NHẬN` → incident `ĐANG_XỬ_LÝ`.

- [ ] **Step 1: Test hỏng:** verify khi `CHỜ` → 409; submit rồi verify approved → remediation `HOÀN_THÀNH`, finding `ĐÃ_KHẮC_PHỤC`, violation `ĐÃ_XỬ_LÝ`; verify từ chối → `ĐANG_THỰC_HIỆN`; `PUT /remediations/:id {status:'HOÀN_THÀNH'}` → status không đổi; tạo penalty → violation `ĐANG_XỬ_LÝ`; tạo response → incident `ĐANG_XỬ_LÝ`.
- [ ] **Step 2:** `npm install && npm test` → FAIL.
- [ ] **Step 3:** Viết `workflow.service.js`, gắn route.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(incident-gis): xác nhận khắc phục và đồng bộ trạng thái UC07-UC08`.

---

### Task 9: Báo cáo, thông báo, quy tắc cảnh báo (incident-gis, UC10)

**Files:**
- Modify: `pccc-service-incident-gis/src/modules/modules.js`, `src/routes/index.js`
- Create: `pccc-service-incident-gis/src/modules/uc10.routes.js`
- Test: `pccc-service-incident-gis/tests/uc10.test.js`

**Interfaces:**
- Quyền `alert_rule`: `/alert-rules` CRUD (filterable `trigger_type, is_active`).
- Quyền `report`: `/reports` list/get/delete; `POST /reports` body `{ code, name, report_type, period_type, from_date?, to_date?, scope_unit_id? }` → `generated_by=req.user.id`; với `report_type` `VI_PHẠM` hoặc `SỰ_CỐ` tính `result_data` ngay từ DB này: `{ total, by_status: {<status>: n} }` trong khoảng ngày (`detected_date` / `occurred_at`). Loại khác để `result_data = null` (P3 tổng hợp từ service khác).
- Không cần quyền riêng (chỉ cần đăng nhập): `GET /notifications/mine?unread=true` (lọc `recipient_user_id = req.user.id`), `POST /notifications/:id/read` (chỉ của chính mình, của người khác → 404).
- Quyền `notification:write`: `POST /notifications` (hệ thống/ADMIN tạo).

- [ ] **Step 1: Test hỏng:** 2 violation `MỚI` + 1 `ĐÃ_XỬ_LÝ` trong tháng → report VI_PHẠM có `result_data.total===3`, `by_status['MỚI']===2`; `to_date < from_date` → 400; user A đọc thông báo của user B → 404; `/notifications/mine?unread=true` chỉ trả thông báo chưa đọc của mình.
- [ ] **Step 2:** `npm test` → FAIL.
- [ ] **Step 3:** Viết `uc10.routes.js`.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(incident-gis): báo cáo, thông báo, cảnh báo UC10`.

---

### Task 10: Quyền và vai trò trong seed (auth)

**Files:**
- Modify: `pccc-service-auth/db/init/02_seed.sql`
- Modify: `pccc-service-auth/package.json`; Create: `tests/setup-env.js`, `tests/helpers.js` (DB `localhost:5433/pccc_auth_test`)
- Test: `pccc-service-auth/tests/seed.test.js`

**Interfaces:**
- Thêm module: `facility, dossier, equipment, safety, checklist, self_inspection, inspection, report, notification, alert_rule` (mỗi module `:read`, `:write`) và quyền lẻ `inspection:approve`.
- Ánh xạ:
  - ADMIN: tất cả (câu CROSS JOIN đã có tự áp).
  - MANAGER: mọi `:read` + `inspection:approve`, `report:write`.
  - INSPECTOR: mọi `:read` + write `inspection, checklist, finding, violation, penalty, remediation, incident, gis, resource, safety, report`.
  - FACILITY_OWNER: read `facility, dossier, equipment, safety, checklist, self_inspection, finding, violation, remediation, notification`; write `dossier, equipment, safety, self_inspection, remediation`.
  - VIEWER: mọi `:read`.
- Seed phải chạy lại được (giữ `ON CONFLICT DO NOTHING`).

- [ ] **Step 1: Test hỏng:** sau `resetDb()`, truy vấn quyền của từng vai trò: FACILITY_OWNER có `self_inspection:write`, không có `inspection:write`; MANAGER có `inspection:approve`; INSPECTOR không có `inspection:approve`; chạy `02_seed.sql` lần 2 không lỗi và không tăng số dòng `role_permissions`.
- [ ] **Step 2:** `npm install && npm test` → FAIL.
- [ ] **Step 3:** Sửa `02_seed.sql`.
- [ ] **Step 4:** `npm test` → PASS.
- [ ] **Step 5:** Commit `feat(auth): quyền và vai trò cho UC02-UC06, UC10`.

---

### Task 11: Chạy thử toàn hệ thống và cập nhật README

**Files:**
- Modify: `firesafe-boilerplate/README.md` (mục "API đã có", "Chạy test", bỏ TODO đã làm)
- Create: `firesafe-boilerplate/scripts/smoke.sh`

**Interfaces:**
- `scripts/smoke.sh`: login admin qua `:3001`, lấy `accessToken`, gọi `GET /health` 5 service và mỗi service một `GET` danh sách (`/users`, `/facilities`, `/equipment`, `/self-inspections`, `/violations`); in `OK`/`FAIL` từng dòng, exit 1 nếu có FAIL.

- [ ] **Step 1:** `docker compose down -v && docker compose up --build -d`, đợi healthy, `docker compose exec -e ADMIN_PASSWORD='Admin@12345' auth npm run seed:admin`.
- [ ] **Step 2:** `bash scripts/smoke.sh` → 10 dòng `OK`, exit 0.
- [ ] **Step 3:** `for s in pccc-service-*; do (cd $s && npm test) || echo "FAIL $s"; done` → không có dòng `FAIL`.
- [ ] **Step 4:** Cập nhật README (bảng route mới theo service, cách tạo DB test, lệnh `npm test`).
- [ ] **Step 5:** Commit `docs: cập nhật README, thêm smoke test` và push `main`.
