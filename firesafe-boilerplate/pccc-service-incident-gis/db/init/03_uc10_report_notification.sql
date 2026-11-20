-- ============================================================
-- UC10 (KHÔNG thuộc phần của Long): Báo cáo, Thông báo, Quy tắc cảnh báo
-- Cùng nằm trong DB pccc_incident_gis. Chạy sau 01_schema.sql.
-- Có thể xoá file này nếu người phụ trách UC10 tự quản lý.
-- ============================================================
CREATE TABLE IF NOT EXISTS reports (
  report_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code           VARCHAR(50) NOT NULL UNIQUE,
  name           VARCHAR(255) NOT NULL,
  report_type    VARCHAR(30) NOT NULL,
  period_type    VARCHAR(20) NOT NULL,
  from_date      DATE,
  to_date        DATE,
  scope_unit_id  UUID,                                 -- Ref
  parameters     JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_data    JSONB,
  file_url       TEXT,
  generated_by   UUID,                                 -- Ref
  generated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (report_type IN ('THỐNG_KÊ_CƠ_SỞ', 'KIỂM_TRA', 'VI_PHẠM', 'SỰ_CỐ', 'TỔNG_HỢP')),
  CHECK (period_type IN ('THÁNG', 'QUÝ', 'NĂM', 'TÙY_CHỌN')),
  CONSTRAINT chk_report_dates CHECK (to_date IS NULL OR from_date IS NULL OR to_date >= from_date)
);

CREATE TABLE IF NOT EXISTS notifications (
  notification_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id  UUID NOT NULL,                    -- Ref
  title              VARCHAR(255) NOT NULL,
  content            TEXT,
  notification_type  VARCHAR(30) NOT NULL,
  ref_type           VARCHAR(30),
  ref_id             UUID,
  channel            VARCHAR(10) NOT NULL DEFAULT 'IN_APP',
  is_read            BOOLEAN NOT NULL DEFAULT FALSE,
  read_at            TIMESTAMPTZ,
  sent_at            TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (notification_type IN ('HẾT_HẠN_TÀI_LIỆU', 'TỚI_HẠN_KIỂM_TRA', 'VI_PHẠM_QUÁ_HẠN', 'SỰ_CỐ', 'HỆ_THỐNG')),
  CHECK (channel IN ('IN_APP', 'EMAIL', 'SMS', 'PUSH'))
);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_user_id, is_read);

CREATE TABLE IF NOT EXISTS alert_rules (
  alert_rule_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code           VARCHAR(50) NOT NULL UNIQUE,
  name           VARCHAR(255) NOT NULL,
  trigger_type   VARCHAR(30) NOT NULL,
  days_before    INTEGER CHECK (days_before >= 0),
  target_roles   JSONB NOT NULL DEFAULT '[]'::jsonb,
  channels       JSONB NOT NULL DEFAULT '["IN_APP"]'::jsonb,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS trg_alert_rules_updated ON alert_rules;
CREATE TRIGGER trg_alert_rules_updated BEFORE UPDATE ON alert_rules FOR EACH ROW EXECUTE FUNCTION set_updated_at();
