-- ============================================================
-- Dữ liệu mẫu cho pccc-service-auth (VAI TRÒ/QUYỀN LÀ MẪU - chỉnh theo đề bài)
-- Quy ước mã quyền: <module>:read | <module>:write
-- Tài khoản admin được tạo bằng:  npm run seed:admin  (cần bcrypt)
-- ============================================================
INSERT INTO roles (code, name, description, is_system) VALUES
  ('ADMIN',          'Quản trị hệ thống',        'Toàn quyền hệ thống',                 TRUE),
  ('MANAGER',        'Lãnh đạo / Quản lý',       'Xem, duyệt, tổng hợp báo cáo',        TRUE),
  ('INSPECTOR',      'Cán bộ kiểm tra',          'Kiểm tra, lập vi phạm, xử lý sự cố',  TRUE),
  ('FACILITY_OWNER', 'Chủ cơ sở',                'Quản lý cơ sở và khắc phục của mình', TRUE),
  ('VIEWER',         'Người xem',                'Chỉ xem dữ liệu',                     TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO permissions (code, name, module, action) VALUES
  ('unit:read', 'Read unit', 'unit', 'read'),
  ('unit:write', 'Write unit', 'unit', 'write'),
  ('user:read', 'Read user', 'user', 'read'),
  ('user:write', 'Write user', 'user', 'write'),
  ('role:read', 'Read role', 'role', 'read'),
  ('role:write', 'Write role', 'role', 'write'),
  ('permission:read', 'Read permission', 'permission', 'read'),
  ('permission:write', 'Write permission', 'permission', 'write'),
  ('finding:read', 'Read finding', 'finding', 'read'),
  ('finding:write', 'Write finding', 'finding', 'write'),
  ('violation:read', 'Read violation', 'violation', 'read'),
  ('violation:write', 'Write violation', 'violation', 'write'),
  ('penalty:read', 'Read penalty', 'penalty', 'read'),
  ('penalty:write', 'Write penalty', 'penalty', 'write'),
  ('remediation:read', 'Read remediation', 'remediation', 'read'),
  ('remediation:write', 'Write remediation', 'remediation', 'write'),
  ('incident:read', 'Read incident', 'incident', 'read'),
  ('incident:write', 'Write incident', 'incident', 'write'),
  ('gis:read', 'Read gis', 'gis', 'read'),
  ('gis:write', 'Write gis', 'gis', 'write'),
  ('resource:read', 'Read resource', 'resource', 'read'),
  ('resource:write', 'Write resource', 'resource', 'write')
ON CONFLICT (code) DO NOTHING;

-- ADMIN: tất cả quyền
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r CROSS JOIN permissions p WHERE r.code = 'ADMIN'
ON CONFLICT DO NOTHING;

-- INSPECTOR: đọc tất cả, ghi các module nghiệp vụ UC07/08/09
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p
  ON (p.action = 'read' OR p.module IN ('finding','violation','penalty','remediation','incident','gis','resource'))
WHERE r.code = 'INSPECTOR'
ON CONFLICT DO NOTHING;

-- MANAGER, VIEWER: chỉ đọc
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p ON p.action = 'read'
WHERE r.code IN ('MANAGER', 'VIEWER')
ON CONFLICT DO NOTHING;
