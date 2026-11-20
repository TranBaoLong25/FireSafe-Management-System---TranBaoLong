-- ============================================================
-- pccc-service-incident-gis  |  UC07 Vi phạm - UC08 Sự cố - UC09 GIS
-- Database: pccc_incident_gis   (PostgreSQL 13+, PostGIS 3+)
-- Cột "Ref" (facility_id, unit_id, ...) trỏ sang service khác => CHỈ lưu ID, KHÔNG có FOREIGN KEY.
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------- UC07: Phát hiện / Vi phạm / Xử phạt / Khắc phục ----------------
CREATE TABLE IF NOT EXISTS findings (
  finding_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id     UUID NOT NULL,                       -- Ref: facility-service
  source_type     VARCHAR(30) NOT NULL,
  source_id       UUID,                                -- Ref: inspection-service
  description     TEXT NOT NULL,
  severity        VARCHAR(20) NOT NULL,
  recommendation  TEXT,
  detected_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  status          VARCHAR(20) NOT NULL DEFAULT 'MỚI',
  evidence_urls   JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (source_type IN ('SELF_INSPECTION', 'OFFICIAL_INSPECTION')),
  CHECK (severity IN ('NHẸ', 'TRUNG_BÌNH', 'NGHIÊM_TRỌNG')),
  CHECK (status IN ('MỚI', 'ĐANG_XỬ_LÝ', 'ĐÃ_KHẮC_PHỤC', 'QUÁ_HẠN'))
);
CREATE INDEX IF NOT EXISTS idx_findings_facility ON findings(facility_id);
CREATE INDEX IF NOT EXISTS idx_findings_status ON findings(status);

CREATE TABLE IF NOT EXISTS violations (
  violation_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  facility_id     UUID NOT NULL,                       -- Ref
  finding_id      UUID REFERENCES findings(finding_id) ON DELETE SET NULL,
  violation_type  VARCHAR(100) NOT NULL,
  description     TEXT,
  legal_basis     TEXT,
  severity        VARCHAR(20) NOT NULL,
  detected_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  status          VARCHAR(20) NOT NULL DEFAULT 'MỚI',
  evidence_urls   JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (severity IN ('NHẸ', 'TRUNG_BÌNH', 'NGHIÊM_TRỌNG')),
  CHECK (status IN ('MỚI', 'ĐANG_XỬ_LÝ', 'ĐÃ_XỬ_LÝ', 'QUÁ_HẠN'))
);
CREATE INDEX IF NOT EXISTS idx_violations_facility ON violations(facility_id);
CREATE INDEX IF NOT EXISTS idx_violations_finding ON violations(finding_id);

CREATE TABLE IF NOT EXISTS administrative_penalties (
  penalty_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  violation_id    UUID NOT NULL REFERENCES violations(violation_id) ON DELETE CASCADE,
  decision_no     VARCHAR(100) NOT NULL UNIQUE,
  decision_date   DATE NOT NULL,
  penalty_form    VARCHAR(20) NOT NULL,
  fine_amount     NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (fine_amount >= 0),
  payment_status  VARCHAR(20) NOT NULL DEFAULT 'CHƯA_NỘP',
  file_url        TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (penalty_form IN ('CẢNH_CÁO', 'PHẠT_TIỀN', 'ĐÌNH_CHỈ')),
  CHECK (payment_status IN ('CHƯA_NỘP', 'ĐÃ_NỘP', 'QUÁ_HẠN'))
);
CREATE INDEX IF NOT EXISTS idx_penalties_violation ON administrative_penalties(violation_id);

CREATE TABLE IF NOT EXISTS remediations (
  remediation_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  finding_id           UUID NOT NULL REFERENCES findings(finding_id) ON DELETE CASCADE,
  violation_id         UUID REFERENCES violations(violation_id) ON DELETE SET NULL,
  action_plan          TEXT NOT NULL,
  responsible_user_id  UUID,                           -- Ref: auth-service
  planned_date         DATE,
  completed_date       DATE,
  result_description   TEXT,
  evidence_urls        JSONB NOT NULL DEFAULT '[]'::jsonb,
  verified_by          UUID,                           -- Ref: auth-service
  verified_at          TIMESTAMPTZ,
  status               VARCHAR(20) NOT NULL DEFAULT 'CHỜ',
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status IN ('CHỜ', 'ĐANG_THỰC_HIỆN', 'CHỜ_XÁC_NHẬN', 'HOÀN_THÀNH'))
);
CREATE INDEX IF NOT EXISTS idx_remediations_finding ON remediations(finding_id);
CREATE INDEX IF NOT EXISTS idx_remediations_violation ON remediations(violation_id);

-- ---------------- UC08: Sự cố cháy, nổ, CNCH ----------------
CREATE TABLE IF NOT EXISTS incidents (
  incident_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code             VARCHAR(50) NOT NULL UNIQUE,
  incident_type    VARCHAR(20) NOT NULL,
  facility_id      UUID,                               -- Ref (nullable)
  occurred_at      TIMESTAMPTZ NOT NULL,
  reported_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  reported_by      UUID,                               -- Ref: auth-service
  address          TEXT,
  latitude         DOUBLE PRECISION CHECK (latitude  BETWEEN -90  AND 90),
  longitude        DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  cause            TEXT,
  description      TEXT,
  burned_area      DOUBLE PRECISION CHECK (burned_area >= 0),
  death_count      INTEGER NOT NULL DEFAULT 0 CHECK (death_count >= 0),
  injury_count     INTEGER NOT NULL DEFAULT 0 CHECK (injury_count >= 0),
  rescued_count    INTEGER NOT NULL DEFAULT 0 CHECK (rescued_count >= 0),
  property_damage  NUMERIC(18,2) CHECK (property_damage >= 0),
  level            VARCHAR(20),
  status           VARCHAR(20) NOT NULL DEFAULT 'TIẾP_NHẬN',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (incident_type IN ('CHÁY', 'NỔ', 'SỰ_CỐ_KHÁC', 'CNCH')),
  CHECK (level IN ('NHỎ', 'TRUNG_BÌNH', 'LỚN', 'RẤT_LỚN')),
  CHECK (status IN ('TIẾP_NHẬN', 'ĐANG_XỬ_LÝ', 'ĐÃ_DẬP_TẮT', 'ĐÃ_KẾT_LUẬN'))
);
CREATE INDEX IF NOT EXISTS idx_incidents_facility ON incidents(facility_id);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_occurred ON incidents(occurred_at DESC);

CREATE TABLE IF NOT EXISTS incident_responses (
  incident_response_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id           UUID NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  unit_id               UUID NOT NULL,                 -- Ref: auth-service (units)
  vehicle_count         INTEGER NOT NULL DEFAULT 0 CHECK (vehicle_count >= 0),
  personnel_count       INTEGER NOT NULL DEFAULT 0 CHECK (personnel_count >= 0),
  arrived_at            TIMESTAMPTZ,
  extinguished_at       TIMESTAMPTZ,
  note                  TEXT
);
CREATE INDEX IF NOT EXISTS idx_incident_responses_incident ON incident_responses(incident_id);

CREATE TABLE IF NOT EXISTS incident_investigations (
  investigation_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id       UUID NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  investigator_id   UUID NOT NULL,                     -- Ref: auth-service
  conclusion        TEXT,
  responsibility    TEXT,
  report_url        TEXT,
  concluded_at      DATE
);
CREATE INDEX IF NOT EXISTS idx_incident_investigations_incident ON incident_investigations(incident_id);

CREATE TABLE IF NOT EXISTS incident_attachments (
  attachment_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id    UUID NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
  file_url       TEXT NOT NULL,
  file_type      VARCHAR(30),
  description    TEXT,
  uploaded_by    UUID,                                 -- Ref: auth-service
  uploaded_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_incident_attachments_incident ON incident_attachments(incident_id);

-- ---------------- UC09: Bản đồ GIS ----------------
CREATE TABLE IF NOT EXISTS gis_layers (
  layer_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(50) NOT NULL UNIQUE,
  name                VARCHAR(255) NOT NULL,
  layer_type          VARCHAR(10) NOT NULL,
  source              VARCHAR(20) NOT NULL,
  style_config        JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_visible_default  BOOLEAN NOT NULL DEFAULT TRUE,
  min_role            VARCHAR(50),
  CHECK (layer_type IN ('POINT', 'LINE', 'POLYGON')),
  CHECK (source IN ('FACILITY', 'EQUIPMENT', 'INCIDENT', 'CUSTOM'))
);

CREATE TABLE IF NOT EXISTS gis_features (
  feature_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  layer_id    UUID NOT NULL REFERENCES gis_layers(layer_id) ON DELETE CASCADE,
  ref_type    VARCHAR(30),
  ref_id      UUID,                                    -- Ref: đối tượng gốc (cơ sở, sự cố, ...)
  name        VARCHAR(255),
  geometry    geometry(Geometry, 4326) NOT NULL,
  properties  JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_gis_features_layer ON gis_features(layer_id);
CREATE INDEX IF NOT EXISTS idx_gis_features_geom ON gis_features USING GIST (geometry);
CREATE INDEX IF NOT EXISTS idx_gis_features_ref ON gis_features(ref_type, ref_id);

CREATE TABLE IF NOT EXISTS firefighting_resources (
  resource_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type  VARCHAR(20) NOT NULL,
  name           VARCHAR(255) NOT NULL,
  unit_id        UUID,                                 -- Ref: auth-service (units)
  latitude       DOUBLE PRECISION NOT NULL CHECK (latitude  BETWEEN -90  AND 90),
  longitude      DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  capacity       DOUBLE PRECISION CHECK (capacity >= 0),
  status         VARCHAR(20) NOT NULL DEFAULT 'SẴN_SÀNG',
  CHECK (resource_type IN ('ĐỘI_PCCC', 'TRỤ_NƯỚC', 'BỂ_NƯỚC', 'XE_CHỮA_CHÁY')),
  CHECK (status IN ('SẴN_SÀNG', 'ĐANG_SỬ_DỤNG', 'HỎNG'))
);
CREATE INDEX IF NOT EXISTS idx_resources_type ON firefighting_resources(resource_type);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['findings','violations','remediations','incidents'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%s_updated ON %I', t, t);
    EXECUTE format('CREATE TRIGGER trg_%s_updated BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;
