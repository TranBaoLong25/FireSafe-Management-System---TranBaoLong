-- Dữ liệu mẫu: các lớp bản đồ mặc định (UC09)
INSERT INTO gis_layers (code, name, layer_type, source, is_visible_default, min_role, style_config) VALUES
  ('FACILITY',  'Cơ sở thuộc diện kiểm tra PCCC', 'POINT', 'FACILITY',  TRUE,  'VIEWER',    '{"color":"#1d4ed8","icon":"building"}'),
  ('INCIDENT',  'Sự cố cháy, nổ, CNCH',           'POINT', 'INCIDENT',  TRUE,  'VIEWER',    '{"color":"#dc2626","icon":"fire"}'),
  ('HYDRANT',   'Trụ nước chữa cháy',             'POINT', 'CUSTOM',    FALSE, 'VIEWER',    '{"color":"#0891b2","icon":"droplet"}'),
  ('FIRE_UNIT', 'Đội PCCC',                       'POINT', 'CUSTOM',    FALSE, 'INSPECTOR', '{"color":"#ea580c","icon":"truck"}')
ON CONFLICT (code) DO NOTHING;
