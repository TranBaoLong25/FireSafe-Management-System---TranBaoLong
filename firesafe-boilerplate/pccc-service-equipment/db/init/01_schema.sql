-- ============================================================
-- pccc-service-equipment  |  UC04 Quản lý điều kiện an toàn PCCC
-- Database: pccc_equipment   (PostgreSQL 13+)
-- Theo ERD Confluence 3.5.3. Cột "Ref" (facility_id, ...) => CHỈ lưu ID, KHÔNG có FOREIGN KEY.
-- GIẢ ĐỊNH (ERD không ghi): các giá trị enum trong CHECK.
-- ============================================================

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------- Thiết bị PCCC ----------------
CREATE TABLE IF NOT EXISTS equipment_types (
  equipment_type_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                    VARCHAR(50)  NOT NULL UNIQUE,
  name                    VARCHAR(255) NOT NULL,
  category                VARCHAR(100),
  maintenance_cycle_days  INTEGER CHECK (maintenance_cycle_days > 0),
  standard_ref            VARCHAR(255)                 -- TCVN / QCVN áp dụng
);

CREATE TABLE IF NOT EXISTS equipment (
  equipment_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                   VARCHAR(50) NOT NULL UNIQUE,
  facility_id            UUID NOT NULL,                -- Ref: facility-service
  equipment_type_id      UUID NOT NULL REFERENCES equipment_types(equipment_type_id) ON DELETE RESTRICT,
  name                   VARCHAR(255) NOT NULL,
  manufacturer           VARCHAR(255),
  model                  VARCHAR(100),
  serial_number          VARCHAR(100),
  location_description   TEXT,
  latitude               DOUBLE PRECISION CHECK (latitude  BETWEEN -90  AND 90),
  longitude              DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  install_date           DATE,
  manufacture_date       DATE,
  warranty_expiry_date   DATE,
  status                 VARCHAR(20) NOT NULL DEFAULT 'HOẠT_ĐỘNG',
  next_maintenance_date  DATE,
  qr_code                VARCHAR(100) UNIQUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status IN ('HOẠT_ĐỘNG', 'HỎNG', 'ĐANG_BẢO_DƯỠNG', 'THANH_LÝ'))
);
CREATE INDEX IF NOT EXISTS idx_equipment_facility ON equipment(facility_id);
CREATE INDEX IF NOT EXISTS idx_equipment_type ON equipment(equipment_type_id);
CREATE INDEX IF NOT EXISTS idx_equipment_next_maint ON equipment(next_maintenance_date);

CREATE TABLE IF NOT EXISTS equipment_maintenances (
  maintenance_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id      UUID NOT NULL REFERENCES equipment(equipment_id) ON DELETE CASCADE,
  maintenance_date  DATE NOT NULL,
  maintenance_type  VARCHAR(20) NOT NULL,
  performed_by      VARCHAR(255),
  result            VARCHAR(20),
  cost              NUMERIC(18,2) CHECK (cost >= 0),
  next_due_date     DATE,
  attachment_url    TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (maintenance_type IN ('ĐỊNH_KỲ', 'SỬA_CHỮA', 'KIỂM_ĐỊNH', 'THAY_THẾ')),
  CHECK (result IN ('ĐẠT', 'KHÔNG_ĐẠT'))
);
CREATE INDEX IF NOT EXISTS idx_maintenances_equipment ON equipment_maintenances(equipment_id);

CREATE TABLE IF NOT EXISTS equipment_certificates (
  certificate_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id    UUID NOT NULL REFERENCES equipment(equipment_id) ON DELETE CASCADE,
  certificate_no  VARCHAR(100) NOT NULL,
  issued_date     DATE,
  expiry_date     DATE,
  issuing_body    VARCHAR(255),
  file_url        TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (expiry_date IS NULL OR issued_date IS NULL OR expiry_date >= issued_date)
);
CREATE INDEX IF NOT EXISTS idx_certificates_equipment ON equipment_certificates(equipment_id);
CREATE INDEX IF NOT EXISTS idx_certificates_expiry ON equipment_certificates(expiry_date);

-- ---------------- Điều kiện an toàn PCCC ----------------
CREATE TABLE IF NOT EXISTS safety_conditions (
  safety_condition_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                       VARCHAR(50)  NOT NULL UNIQUE,
  name                       VARCHAR(255) NOT NULL,
  category                   VARCHAR(100),
  description                TEXT,
  legal_basis                TEXT,
  applicable_facility_types  JSONB NOT NULL DEFAULT '[]'::jsonb   -- mảng facility_type_id (Ref)
);

CREATE TABLE IF NOT EXISTS facility_safety_conditions (
  facility_safety_condition_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id                   UUID NOT NULL,         -- Ref: facility-service
  safety_condition_id           UUID NOT NULL REFERENCES safety_conditions(safety_condition_id) ON DELETE CASCADE,
  compliance_status             VARCHAR(20) NOT NULL DEFAULT 'CHƯA_ĐÁNH_GIÁ',
  assessed_at                   TIMESTAMPTZ,
  assessed_by                   UUID,                  -- Ref: auth-service
  note                          TEXT,
  evidence_url                  TEXT,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (facility_id, safety_condition_id),
  CHECK (compliance_status IN ('CHƯA_ĐÁNH_GIÁ', 'ĐẠT', 'KHÔNG_ĐẠT'))
);
CREATE INDEX IF NOT EXISTS idx_fsc_condition ON facility_safety_conditions(safety_condition_id);

-- ---------------- Nguồn nước chữa cháy ----------------
CREATE TABLE IF NOT EXISTS water_sources (
  water_source_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id      UUID,                               -- Ref: facility-service (NULL = nguồn nước công cộng)
  source_type      VARCHAR(20) NOT NULL,
  capacity         DOUBLE PRECISION CHECK (capacity >= 0),   -- m3
  flow_rate        DOUBLE PRECISION CHECK (flow_rate >= 0),  -- l/s
  latitude         DOUBLE PRECISION CHECK (latitude  BETWEEN -90  AND 90),
  longitude        DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  status           VARCHAR(20) NOT NULL DEFAULT 'SỬ_DỤNG_ĐƯỢC',
  CHECK (source_type IN ('TRỤ_NƯỚC', 'BỂ_NƯỚC', 'HỒ_AO', 'SÔNG_SUỐI', 'KHÁC')),
  CHECK (status IN ('SỬ_DỤNG_ĐƯỢC', 'HẠN_CHẾ', 'HỎNG'))
);
CREATE INDEX IF NOT EXISTS idx_water_sources_facility ON water_sources(facility_id);

DROP TRIGGER IF EXISTS trg_equipment_updated ON equipment;
CREATE TRIGGER trg_equipment_updated BEFORE UPDATE ON equipment FOR EACH ROW EXECUTE FUNCTION set_updated_at();
