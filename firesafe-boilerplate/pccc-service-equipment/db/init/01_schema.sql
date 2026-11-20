-- ============================================================
-- pccc-service-equipment  |  Quản lý thiết bị PCCC
-- TODO: viết schema khi nhóm chốt model (cột "Ref" chỉ lưu ID, không FK sang service khác).
-- Mẫu bắt đầu:
--   CREATE TABLE IF NOT EXISTS <ten_bang> (
--     <ten>_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     ...
--     created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
--     updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
--   );
-- ============================================================

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
