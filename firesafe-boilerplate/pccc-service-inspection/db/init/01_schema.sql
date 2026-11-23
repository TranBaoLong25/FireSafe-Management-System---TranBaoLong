-- ============================================================
-- pccc-service-inspection  |  UC05 Tự kiểm tra của cơ sở - UC06 Kiểm tra của cơ quan Công an
-- Database: pccc_inspection   (PostgreSQL 13+)
-- Theo ERD Confluence 3.5.4 + Class Diagram 3.4.4.
--   inspections là bảng cha (lớp trừu tượng Inspection); self_inspections / official_inspections là bảng con 1-1.
--   inspection_result_items gắn với inspections nên dùng chung cho cả 2 loại kiểm tra.
-- Cột "Ref" (facility_id, user_id, unit_id, ...) => CHỈ lưu ID, KHÔNG có FOREIGN KEY.
-- GIẢ ĐỊNH (ERD không ghi): các giá trị enum trong CHECK.
-- inspection_kind dùng cùng giá trị với findings.source_type bên incident-gis.
-- ============================================================

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------- Mẫu phiếu kiểm tra (checklist) ----------------
CREATE TABLE IF NOT EXISTS inspection_templates (
  template_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              VARCHAR(50)  NOT NULL UNIQUE,
  name              VARCHAR(255) NOT NULL,
  inspection_kind   VARCHAR(30)  NOT NULL,
  facility_type_id  UUID,                              -- Ref: facility-service (NULL = áp dụng mọi loại hình)
  version           VARCHAR(20)  NOT NULL DEFAULT '1.0',
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (inspection_kind IN ('SELF_INSPECTION', 'OFFICIAL_INSPECTION'))
);

CREATE TABLE IF NOT EXISTS inspection_template_items (
  template_item_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id       UUID NOT NULL REFERENCES inspection_templates(template_id) ON DELETE CASCADE,
  order_no          INTEGER NOT NULL,
  content           TEXT NOT NULL,
  group_name        VARCHAR(255),
  legal_basis       TEXT,
  is_critical       BOOLEAN NOT NULL DEFAULT FALSE,
  answer_type       VARCHAR(20) NOT NULL DEFAULT 'ĐẠT_KHÔNG_ĐẠT',
  UNIQUE (template_id, order_no),
  CHECK (answer_type IN ('ĐẠT_KHÔNG_ĐẠT', 'SỐ', 'VĂN_BẢN'))
);

-- ---------------- Lần kiểm tra (bảng cha) ----------------
CREATE TABLE IF NOT EXISTS inspections (
  inspection_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_kind  VARCHAR(30) NOT NULL,
  facility_id      UUID NOT NULL,                      -- Ref: facility-service
  inspection_date  DATE,
  overall_result   VARCHAR(20),
  status           VARCHAR(20) NOT NULL DEFAULT 'NHÁP',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (inspection_kind IN ('SELF_INSPECTION', 'OFFICIAL_INSPECTION')),
  CHECK (overall_result IN ('ĐẠT', 'KHÔNG_ĐẠT', 'ĐẠT_CÓ_KIẾN_NGHỊ')),
  CHECK (status IN ('NHÁP', 'ĐANG_THỰC_HIỆN', 'HOÀN_THÀNH', 'HỦY'))
);
CREATE INDEX IF NOT EXISTS idx_inspections_facility ON inspections(facility_id);
CREATE INDEX IF NOT EXISTS idx_inspections_kind_date ON inspections(inspection_kind, inspection_date DESC);

CREATE TABLE IF NOT EXISTS inspection_result_items (
  result_item_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id     UUID NOT NULL REFERENCES inspections(inspection_id) ON DELETE CASCADE,
  template_item_id  UUID NOT NULL REFERENCES inspection_template_items(template_item_id) ON DELETE RESTRICT,
  result            VARCHAR(20),
  finding           TEXT,
  recommendation    TEXT,
  evidence_urls     JSONB NOT NULL DEFAULT '[]'::jsonb,
  UNIQUE (inspection_id, template_item_id),
  CHECK (result IN ('ĐẠT', 'KHÔNG_ĐẠT', 'KHÔNG_ÁP_DỤNG'))
);
CREATE INDEX IF NOT EXISTS idx_result_items_template_item ON inspection_result_items(template_item_id);

-- ---------------- UC05: Tự kiểm tra của cơ sở ----------------
CREATE TABLE IF NOT EXISTS self_inspections (
  self_inspection_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id       UUID NOT NULL UNIQUE REFERENCES inspections(inspection_id) ON DELETE CASCADE,
  template_id         UUID NOT NULL REFERENCES inspection_templates(template_id) ON DELETE RESTRICT,
  code                VARCHAR(50) NOT NULL UNIQUE,
  facility_id         UUID NOT NULL,                   -- Ref: facility-service
  inspection_date     DATE NOT NULL,
  inspector_user_id   UUID,                            -- Ref: auth-service
  period              VARCHAR(20),                     -- vd: 2026-Q4, 2026-11
  overall_result      VARCHAR(20),
  note                TEXT,
  status              VARCHAR(20) NOT NULL DEFAULT 'NHÁP',
  submitted_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (overall_result IN ('ĐẠT', 'KHÔNG_ĐẠT', 'ĐẠT_CÓ_KIẾN_NGHỊ')),
  CHECK (status IN ('NHÁP', 'ĐÃ_NỘP', 'ĐÃ_TIẾP_NHẬN'))
);
CREATE INDEX IF NOT EXISTS idx_self_inspections_facility ON self_inspections(facility_id);
CREATE INDEX IF NOT EXISTS idx_self_inspections_template ON self_inspections(template_id);

-- ---------------- UC06: Kế hoạch & kiểm tra của cơ quan Công an ----------------
CREATE TABLE IF NOT EXISTS inspection_plans (
  plan_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         VARCHAR(50)  NOT NULL UNIQUE,
  name         VARCHAR(255) NOT NULL,
  year         INTEGER NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  quarter      INTEGER CHECK (quarter BETWEEN 1 AND 4),
  unit_id      UUID,                                   -- Ref: auth-service (units)
  approved_by  UUID,                                   -- Ref: auth-service
  approved_at  TIMESTAMPTZ,
  status       VARCHAR(20) NOT NULL DEFAULT 'NHÁP',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status IN ('NHÁP', 'CHỜ_DUYỆT', 'ĐÃ_DUYỆT', 'HỦY'))
);
CREATE INDEX IF NOT EXISTS idx_plans_unit_year ON inspection_plans(unit_id, year);

CREATE TABLE IF NOT EXISTS inspection_plan_facilities (
  plan_facility_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id           UUID NOT NULL REFERENCES inspection_plans(plan_id) ON DELETE CASCADE,
  facility_id       UUID NOT NULL,                     -- Ref: facility-service
  scheduled_date    DATE,
  status            VARCHAR(20) NOT NULL DEFAULT 'CHƯA_KIỂM_TRA',
  UNIQUE (plan_id, facility_id),
  CHECK (status IN ('CHƯA_KIỂM_TRA', 'ĐÃ_KIỂM_TRA', 'HOÃN'))
);
CREATE INDEX IF NOT EXISTS idx_plan_facilities_facility ON inspection_plan_facilities(facility_id);

CREATE TABLE IF NOT EXISTS official_inspections (
  official_inspection_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id           UUID NOT NULL UNIQUE REFERENCES inspections(inspection_id) ON DELETE CASCADE,
  plan_id                 UUID REFERENCES inspection_plans(plan_id) ON DELETE SET NULL,  -- NULL = kiểm tra đột xuất
  code                    VARCHAR(50) NOT NULL UNIQUE,
  facility_id             UUID NOT NULL,               -- Ref: facility-service
  inspection_type         VARCHAR(20) NOT NULL,
  decision_no             VARCHAR(100),
  decision_date           DATE,
  scheduled_date          DATE,
  start_time              TIMESTAMPTZ,
  end_time                TIMESTAMPTZ,
  lead_inspector_id       UUID,                        -- Ref: auth-service
  management_unit_id      UUID,                        -- Ref: auth-service (units)
  overall_result          VARCHAR(20),
  status                  VARCHAR(20) NOT NULL DEFAULT 'CHỜ_KIỂM_TRA',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_time IS NULL OR start_time IS NULL OR end_time >= start_time),
  CHECK (inspection_type IN ('ĐỊNH_KỲ', 'ĐỘT_XUẤT')),
  CHECK (overall_result IN ('ĐẠT', 'KHÔNG_ĐẠT', 'ĐẠT_CÓ_KIẾN_NGHỊ')),
  CHECK (status IN ('CHỜ_KIỂM_TRA', 'ĐANG_KIỂM_TRA', 'HOÀN_THÀNH', 'HỦY'))
);
CREATE INDEX IF NOT EXISTS idx_official_facility ON official_inspections(facility_id);
CREATE INDEX IF NOT EXISTS idx_official_plan ON official_inspections(plan_id);
CREATE INDEX IF NOT EXISTS idx_official_status ON official_inspections(status);

CREATE TABLE IF NOT EXISTS inspection_team_members (
  team_member_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  official_inspection_id  UUID NOT NULL REFERENCES official_inspections(official_inspection_id) ON DELETE CASCADE,
  user_id                 UUID NOT NULL,               -- Ref: auth-service
  role                    VARCHAR(20) NOT NULL DEFAULT 'THÀNH_VIÊN',
  UNIQUE (official_inspection_id, user_id),
  CHECK (role IN ('TRƯỞNG_ĐOÀN', 'THÀNH_VIÊN', 'THƯ_KÝ'))
);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON inspection_team_members(user_id);

-- Biên bản kiểm tra
CREATE TABLE IF NOT EXISTS inspection_reports (
  inspection_report_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  official_inspection_id   UUID NOT NULL REFERENCES official_inspections(official_inspection_id) ON DELETE CASCADE,
  report_no                VARCHAR(100) NOT NULL UNIQUE,
  report_date              DATE NOT NULL,
  content                  TEXT,
  conclusion               TEXT,
  facility_representative  VARCHAR(255),
  signed_file_url          TEXT,
  status                   VARCHAR(20) NOT NULL DEFAULT 'NHÁP',
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status IN ('NHÁP', 'ĐÃ_KÝ'))
);
CREATE INDEX IF NOT EXISTS idx_reports_official ON inspection_reports(official_inspection_id);

DROP TRIGGER IF EXISTS trg_self_inspections_updated ON self_inspections;
CREATE TRIGGER trg_self_inspections_updated BEFORE UPDATE ON self_inspections FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_plans_updated ON inspection_plans;
CREATE TRIGGER trg_plans_updated BEFORE UPDATE ON inspection_plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_official_updated ON official_inspections;
CREATE TRIGGER trg_official_updated BEFORE UPDATE ON official_inspections FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_reports_updated ON inspection_reports;
CREATE TRIGGER trg_reports_updated BEFORE UPDATE ON inspection_reports FOR EACH ROW EXECUTE FUNCTION set_updated_at();
