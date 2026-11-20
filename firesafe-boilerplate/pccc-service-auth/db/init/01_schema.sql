-- ============================================================
-- pccc-service-auth  |  UC01 Quản trị hệ thống và người dùng
-- Database: pccc_auth   (PostgreSQL 13+)
-- ============================================================

-- Hàm tự cập nhật updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS units (
  unit_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code           VARCHAR(50)  NOT NULL UNIQUE,
  name           VARCHAR(255) NOT NULL,
  parent_id      UUID REFERENCES units(unit_id) ON DELETE SET NULL,
  level          VARCHAR(30),
  province_code  VARCHAR(20),
  district_code  VARCHAR(20),
  ward_code      VARCHAR(20),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_units_not_self_parent CHECK (parent_id IS NULL OR parent_id <> unit_id)
);
CREATE INDEX IF NOT EXISTS idx_units_parent ON units(parent_id);

CREATE TABLE IF NOT EXISTS users (
  user_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username            VARCHAR(100) NOT NULL UNIQUE,
  password_hash       VARCHAR(255) NOT NULL,
  full_name           VARCHAR(255) NOT NULL,
  email               VARCHAR(255) UNIQUE,
  phone               VARCHAR(20),
  id_number           VARCHAR(20),
  unit_id             UUID REFERENCES units(unit_id) ON DELETE SET NULL,
  status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  last_login_at       TIMESTAMPTZ,
  failed_login_count  INTEGER NOT NULL DEFAULT 0,
  locked_until        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED'))
);
CREATE INDEX IF NOT EXISTS idx_users_unit ON users(unit_id);

CREATE TABLE IF NOT EXISTS roles (
  role_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         VARCHAR(50)  NOT NULL UNIQUE,
  name         VARCHAR(255) NOT NULL,
  description  TEXT,
  is_system    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS permissions (
  permission_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code           VARCHAR(100) NOT NULL UNIQUE,
  name           VARCHAR(255) NOT NULL,
  module         VARCHAR(50)  NOT NULL,
  action         VARCHAR(50)  NOT NULL
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_role_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id       UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  scope_type    VARCHAR(30),
  scope_id      UUID,
  assigned_by   UUID,
  assigned_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_roles
  ON user_roles(user_id, role_id, COALESCE(scope_type, ''), COALESCE(scope_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id        UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  permission_id  UUID NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX IF NOT EXISTS idx_role_permissions_perm ON role_permissions(permission_id);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  refresh_token_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  token_hash        VARCHAR(255) NOT NULL UNIQUE,
  expires_at        TIMESTAMPTZ NOT NULL,
  revoked           BOOLEAN NOT NULL DEFAULT FALSE,
  revoked_at        TIMESTAMPTZ,
  device_info       VARCHAR(255),
  ip_address        VARCHAR(45),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
  audit_log_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID REFERENCES users(user_id) ON DELETE SET NULL,
  action         VARCHAR(100) NOT NULL,
  resource_type  VARCHAR(100),
  resource_id    VARCHAR(100),
  old_value      JSONB,
  new_value      JSONB,
  ip_address     VARCHAR(45),
  request_id     VARCHAR(100),
  performed_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_time ON audit_logs(performed_at DESC);

DROP TRIGGER IF EXISTS trg_units_updated ON units;
CREATE TRIGGER trg_units_updated BEFORE UPDATE ON units FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_users_updated ON users;
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
