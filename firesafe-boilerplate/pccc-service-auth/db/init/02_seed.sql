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

-- Quyền cho UC02-UC06, UC10 (bổ sung 22/11/2026)
INSERT INTO permissions (code, name, module, action) VALUES
  ('facility:read', 'Xem cơ sở (UC02)', 'facility', 'read'),
  ('facility:write', 'Ghi cơ sở (UC02)', 'facility', 'write'),
  ('dossier:read', 'Xem hồ sơ, tài liệu PCCC (UC03)', 'dossier', 'read'),
  ('dossier:write', 'Ghi hồ sơ, tài liệu PCCC (UC03)', 'dossier', 'write'),
  ('equipment:read', 'Xem thiết bị PCCC (UC04)', 'equipment', 'read'),
  ('equipment:write', 'Ghi thiết bị PCCC (UC04)', 'equipment', 'write'),
  ('safety:read', 'Xem điều kiện an toàn, nguồn nước (UC04)', 'safety', 'read'),
  ('safety:write', 'Ghi điều kiện an toàn, nguồn nước (UC04)', 'safety', 'write'),
  ('checklist:read', 'Xem mẫu phiếu kiểm tra (UC05-06)', 'checklist', 'read'),
  ('checklist:write', 'Ghi mẫu phiếu kiểm tra (UC05-06)', 'checklist', 'write'),
  ('self_inspection:read', 'Xem tự kiểm tra (UC05)', 'self_inspection', 'read'),
  ('self_inspection:write', 'Ghi tự kiểm tra (UC05)', 'self_inspection', 'write'),
  ('inspection:read', 'Xem kiểm tra của cơ quan Công an (UC06)', 'inspection', 'read'),
  ('inspection:write', 'Ghi kiểm tra của cơ quan Công an (UC06)', 'inspection', 'write'),
  ('report:read', 'Xem báo cáo (UC10)', 'report', 'read'),
  ('report:write', 'Ghi báo cáo (UC10)', 'report', 'write'),
  ('notification:read', 'Xem thông báo (UC10)', 'notification', 'read'),
  ('notification:write', 'Ghi thông báo (UC10)', 'notification', 'write'),
  ('alert_rule:read', 'Xem quy tắc cảnh báo (UC10)', 'alert_rule', 'read'),
  ('alert_rule:write', 'Ghi quy tắc cảnh báo (UC10)', 'alert_rule', 'write'),
  ('inspection:approve', 'Phê duyệt kế hoạch kiểm tra (UC06)', 'inspection', 'approve')
ON CONFLICT (code) DO NOTHING;

-- ADMIN: tất cả quyền
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r CROSS JOIN permissions p WHERE r.code = 'ADMIN'
ON CONFLICT DO NOTHING;

-- INSPECTOR: đọc tất cả; ghi nghiệp vụ kiểm tra, vi phạm, sự cố, GIS, báo cáo
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p
  ON (p.action = 'read' OR (p.action = 'write' AND p.module IN ('finding','violation','penalty','remediation','incident','gis','resource','inspection','checklist','safety','report')))
WHERE r.code = 'INSPECTOR'
ON CONFLICT DO NOTHING;

-- MANAGER: đọc tất cả; phê duyệt kế hoạch kiểm tra; lập báo cáo
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p
  ON (p.action = 'read' OR p.code IN ('inspection:approve','report:write'))
WHERE r.code = 'MANAGER'
ON CONFLICT DO NOTHING;

-- FACILITY_OWNER: xem cơ sở của mình; ghi hồ sơ, thiết bị, tự kiểm tra, khắc phục
-- (giới hạn "chỉ cơ sở của mình" xử lý ở tầng API, giai đoạn P4)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p
  ON (p.code IN ('facility:read','dossier:read','equipment:read','safety:read','checklist:read','self_inspection:read','finding:read','violation:read','remediation:read','notification:read','dossier:write','equipment:write','safety:write','self_inspection:write','remediation:write'))
WHERE r.code = 'FACILITY_OWNER'
ON CONFLICT DO NOTHING;

-- VIEWER: chỉ đọc
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r JOIN permissions p
  ON (p.action = 'read')
WHERE r.code = 'VIEWER'
ON CONFLICT DO NOTHING;

