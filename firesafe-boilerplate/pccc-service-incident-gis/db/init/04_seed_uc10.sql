-- ============================================================
-- Dữ liệu mẫu UC10: quy tắc cảnh báo mặc định
-- File chạy SAU 03_uc10_report_notification.sql (bảng alert_rules tạo ở file 03).
-- trigger_type dùng cùng bộ giá trị với notifications.notification_type.
-- Chạy lại nhiều lần không lỗi.
-- ============================================================
INSERT INTO alert_rules (code, name, trigger_type, days_before, target_roles, channels, is_active) VALUES
  ('TAI_LIEU_SAP_HET_HAN', 'Tài liệu PCCC sắp hết hạn (30 ngày)',           'HẾT_HẠN_TÀI_LIỆU',  30, '["FACILITY_OWNER"]',              '["IN_APP","EMAIL"]', TRUE),
  ('BAO_DUONG_TOI_HAN',    'Thiết bị PCCC tới hạn bảo dưỡng (7 ngày)',      'HẾT_HẠN_TÀI_LIỆU',   7, '["FACILITY_OWNER"]',              '["IN_APP"]',         TRUE),
  ('KIEM_TRA_TOI_HAN',     'Sắp tới lịch kiểm tra theo kế hoạch (7 ngày)',  'TỚI_HẠN_KIỂM_TRA',   7, '["INSPECTOR","FACILITY_OWNER"]',  '["IN_APP","EMAIL"]', TRUE),
  ('KHAC_PHUC_QUA_HAN',    'Vi phạm quá hạn khắc phục',                     'VI_PHẠM_QUÁ_HẠN',    0, '["INSPECTOR","MANAGER"]',         '["IN_APP","EMAIL"]', TRUE),
  ('SU_CO_MOI',            'Có sự cố cháy, nổ, CNCH mới tiếp nhận',         'SỰ_CỐ',              0, '["MANAGER","INSPECTOR"]',         '["IN_APP","PUSH"]',  TRUE)
ON CONFLICT (code) DO NOTHING;
