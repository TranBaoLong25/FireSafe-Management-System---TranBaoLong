-- ============================================================
-- pccc-service-facility  |  UC02 Quản lý danh mục & hồ sơ cơ sở - UC03 Hồ sơ & tài liệu PCCC
-- Database: pccc_facility   (PostgreSQL 13+)
-- Theo ERD Confluence 3.5.2. Cột "Ref" trỏ sang service khác => CHỈ lưu ID, KHÔNG có FOREIGN KEY.
-- GIẢ ĐỊNH (ERD không ghi): các giá trị enum trong CHECK, cột "group" đổi tên thành facility_group
-- (GROUP là từ khóa SQL).
-- ============================================================

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------- Danh mục loại hình cơ sở ----------------
CREATE TABLE IF NOT EXISTS facility_types (
  facility_type_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(50)  NOT NULL UNIQUE,
  name                VARCHAR(255) NOT NULL,
  facility_group      VARCHAR(100),
  default_risk_level  VARCHAR(20),
  CHECK (default_risk_level IN ('THẤP', 'TRUNG_BÌNH', 'CAO'))
);

-- ---------------- Cơ sở ----------------
CREATE TABLE IF NOT EXISTS facilities (
  facility_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_type_id        UUID NOT NULL REFERENCES facility_types(facility_type_id) ON DELETE RESTRICT,
  code                    VARCHAR(50)  NOT NULL UNIQUE,
  name                    VARCHAR(255) NOT NULL,
  management_unit_id      UUID,                        -- Ref: auth-service (units)
  risk_level              VARCHAR(20),
  is_fire_safety_managed  BOOLEAN NOT NULL DEFAULT TRUE,
  address                 TEXT,
  province_code           VARCHAR(20),
  district_code           VARCHAR(20),
  ward_code               VARCHAR(20),
  latitude                DOUBLE PRECISION CHECK (latitude  BETWEEN -90  AND 90),
  longitude               DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  total_area              DOUBLE PRECISION CHECK (total_area >= 0),
  building_area           DOUBLE PRECISION CHECK (building_area >= 0),
  floors                  INTEGER CHECK (floors >= 0),
  height                  DOUBLE PRECISION CHECK (height >= 0),
  employee_count          INTEGER CHECK (employee_count >= 0),
  operation_start_date    DATE,
  business_line           VARCHAR(255),
  status                  VARCHAR(20) NOT NULL DEFAULT 'HOẠT_ĐỘNG',
  created_by              UUID,                        -- Ref: auth-service
  updated_by              UUID,                        -- Ref: auth-service
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (risk_level IN ('THẤP', 'TRUNG_BÌNH', 'CAO')),
  CHECK (status IN ('HOẠT_ĐỘNG', 'TẠM_DỪNG', 'NGỪNG_HOẠT_ĐỘNG'))
);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON facilities(facility_type_id);
CREATE INDEX IF NOT EXISTS idx_facilities_unit ON facilities(management_unit_id);
CREATE INDEX IF NOT EXISTS idx_facilities_area ON facilities(province_code, district_code, ward_code);
CREATE INDEX IF NOT EXISTS idx_facilities_status ON facilities(status);

-- ---------------- Tổ chức / doanh nghiệp sở hữu ----------------
CREATE TABLE IF NOT EXISTS organizations (
  organization_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                   VARCHAR(255) NOT NULL,
  tax_code               VARCHAR(20) UNIQUE,
  business_license_no    VARCHAR(100),
  legal_representative   VARCHAR(255),
  phone                  VARCHAR(20),
  email                  VARCHAR(255),
  address                TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS facility_owners (
  facility_owner_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id        UUID NOT NULL REFERENCES facilities(facility_id) ON DELETE CASCADE,
  organization_id    UUID REFERENCES organizations(organization_id) ON DELETE SET NULL,
  owner_user_id      UUID,                             -- Ref: auth-service (tài khoản chủ cơ sở)
  role               VARCHAR(50),
  from_date          DATE,
  to_date            DATE,
  CHECK (to_date IS NULL OR from_date IS NULL OR to_date >= from_date)
);
CREATE INDEX IF NOT EXISTS idx_facility_owners_facility ON facility_owners(facility_id);
CREATE INDEX IF NOT EXISTS idx_facility_owners_org ON facility_owners(organization_id);
CREATE INDEX IF NOT EXISTS idx_facility_owners_user ON facility_owners(owner_user_id);

CREATE TABLE IF NOT EXISTS facility_contacts (
  contact_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id  UUID NOT NULL REFERENCES facilities(facility_id) ON DELETE CASCADE,
  full_name    VARCHAR(255) NOT NULL,
  position     VARCHAR(100),
  phone        VARCHAR(20),
  email        VARCHAR(255),
  is_primary   BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_facility_contacts_facility ON facility_contacts(facility_id);
-- Mỗi cơ sở tối đa 1 người liên hệ chính
CREATE UNIQUE INDEX IF NOT EXISTS uq_facility_contacts_primary ON facility_contacts(facility_id) WHERE is_primary;

-- ---------------- UC03: Hồ sơ & tài liệu PCCC ----------------
CREATE TABLE IF NOT EXISTS fire_safety_dossiers (
  dossier_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id           UUID NOT NULL REFERENCES facilities(facility_id) ON DELETE CASCADE,
  dossier_no            VARCHAR(50) NOT NULL UNIQUE,
  status                VARCHAR(20) NOT NULL DEFAULT 'CHƯA_ĐẦY_ĐỦ',
  completeness_percent  NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (completeness_percent BETWEEN 0 AND 100),
  last_reviewed_at      TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status IN ('CHƯA_ĐẦY_ĐỦ', 'ĐẦY_ĐỦ', 'CẦN_BỔ_SUNG'))
);
CREATE INDEX IF NOT EXISTS idx_dossiers_facility ON fire_safety_dossiers(facility_id);

CREATE TABLE IF NOT EXISTS document_types (
  document_type_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                       VARCHAR(50)  NOT NULL UNIQUE,
  name                       VARCHAR(255) NOT NULL,
  is_required                BOOLEAN NOT NULL DEFAULT FALSE,
  has_expiry                 BOOLEAN NOT NULL DEFAULT FALSE,
  applicable_facility_types  JSONB NOT NULL DEFAULT '[]'::jsonb   -- mảng facility_type_id
);

CREATE TABLE IF NOT EXISTS documents (
  document_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dossier_id         UUID NOT NULL REFERENCES fire_safety_dossiers(dossier_id) ON DELETE CASCADE,
  document_type_id   UUID NOT NULL REFERENCES document_types(document_type_id) ON DELETE RESTRICT,
  title              VARCHAR(255) NOT NULL,
  document_no        VARCHAR(100),
  issue_date         DATE,
  expiry_date        DATE,
  issuing_authority  VARCHAR(255),
  file_url           TEXT,
  file_name          VARCHAR(255),
  file_size          BIGINT CHECK (file_size >= 0),
  mime_type          VARCHAR(100),
  version            INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  status             VARCHAR(20) NOT NULL DEFAULT 'HIỆU_LỰC',
  uploaded_by        UUID,                             -- Ref: auth-service
  uploaded_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (expiry_date IS NULL OR issue_date IS NULL OR expiry_date >= issue_date),
  CHECK (status IN ('HIỆU_LỰC', 'SẮP_HẾT_HẠN', 'HẾT_HẠN', 'THU_HỒI'))
);
CREATE INDEX IF NOT EXISTS idx_documents_dossier ON documents(dossier_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(document_type_id);
CREATE INDEX IF NOT EXISTS idx_documents_expiry ON documents(expiry_date);

CREATE TABLE IF NOT EXISTS document_versions (
  document_version_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id          UUID NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
  version_no           INTEGER NOT NULL CHECK (version_no >= 1),
  file_url             TEXT NOT NULL,
  uploaded_by          UUID,                           -- Ref: auth-service
  uploaded_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  change_note          TEXT,
  UNIQUE (document_id, version_no)
);

CREATE TABLE IF NOT EXISTS fire_fighting_plans (
  fire_fighting_plan_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id            UUID NOT NULL REFERENCES facilities(facility_id) ON DELETE CASCADE,
  document_id            UUID REFERENCES documents(document_id) ON DELETE SET NULL,
  plan_type              VARCHAR(50) NOT NULL,
  approved_date          DATE,
  approved_by            UUID,                         -- Ref: auth-service
  drill_frequency        VARCHAR(30),
  last_drill_date        DATE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ff_plans_facility ON fire_fighting_plans(facility_id);

DROP TRIGGER IF EXISTS trg_facilities_updated ON facilities;
CREATE TRIGGER trg_facilities_updated BEFORE UPDATE ON facilities FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_organizations_updated ON organizations;
CREATE TRIGGER trg_organizations_updated BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_dossiers_updated ON fire_safety_dossiers;
CREATE TRIGGER trg_dossiers_updated BEFORE UPDATE ON fire_safety_dossiers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_ff_plans_updated ON fire_fighting_plans;
CREATE TRIGGER trg_ff_plans_updated BEFORE UPDATE ON fire_fighting_plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();
