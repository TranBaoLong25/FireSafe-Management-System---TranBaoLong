-- ============================================================
-- Dữ liệu danh mục cho pccc-service-inspection: 2 mẫu phiếu kiểm tra
--   TKT_CO_BAN : phiếu tự kiểm tra định kỳ của cơ sở (UC05)
--   KT_CO_QUAN : phiếu kiểm tra của cơ quan Công an (UC06)
-- facility_type_id = NULL => áp dụng mọi loại hình cơ sở.
-- Chạy lại nhiều lần không lỗi.
-- ============================================================

INSERT INTO inspection_templates (code, name, inspection_kind, version, is_active) VALUES
  ('TKT_CO_BAN', 'Phiếu tự kiểm tra an toàn PCCC định kỳ của cơ sở',  'SELF_INSPECTION',     '1.0', TRUE),
  ('KT_CO_QUAN', 'Phiếu kiểm tra an toàn PCCC của cơ quan Công an',    'OFFICIAL_INSPECTION', '1.0', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Mục của phiếu tự kiểm tra
INSERT INTO inspection_template_items (template_id, order_no, group_name, content, is_critical, answer_type)
SELECT t.template_id, v.order_no, v.group_name, v.content, v.is_critical, 'ĐẠT_KHÔNG_ĐẠT'
  FROM inspection_templates t
  CROSS JOIN (VALUES
    (1,  'Quản lý',     'Nội quy, biển cấm, biển báo, sơ đồ thoát nạn đầy đủ, rõ ràng',          FALSE),
    (2,  'Quản lý',     'Hồ sơ PCCC được cập nhật, tài liệu còn hiệu lực',                       FALSE),
    (3,  'Lực lượng',   'Người được phân công PCCC có mặt, nắm được nhiệm vụ',                   FALSE),
    (4,  'Phương tiện', 'Bình chữa cháy đủ số lượng, còn áp lực, đặt đúng vị trí',               TRUE),
    (5,  'Phương tiện', 'Hệ thống báo cháy hoạt động bình thường, không báo lỗi',                TRUE),
    (6,  'Phương tiện', 'Họng nước, vòi, lăng chữa cháy đầy đủ; máy bơm chạy thử đạt',           FALSE),
    (7,  'Thoát nạn',   'Lối thoát nạn thông thoáng, cửa không bị khóa, không để hàng hóa',       TRUE),
    (8,  'Thoát nạn',   'Đèn sự cố, đèn chỉ dẫn thoát nạn hoạt động',                             FALSE),
    (9,  'Điện',        'Không có dây điện hở, ổ cắm quá tải, thiết bị điện bất thường',          TRUE),
    (10, 'Chất cháy',   'Hàng hóa, chất dễ cháy được sắp xếp gọn, cách xa nguồn nhiệt',          FALSE)
  ) AS v(order_no, group_name, content, is_critical)
 WHERE t.code = 'TKT_CO_BAN'
ON CONFLICT (template_id, order_no) DO NOTHING;

-- Mục của phiếu kiểm tra của cơ quan Công an
INSERT INTO inspection_template_items (template_id, order_no, group_name, content, legal_basis, is_critical, answer_type)
SELECT t.template_id, v.order_no, v.group_name, v.content, v.legal_basis, v.is_critical, 'ĐẠT_KHÔNG_ĐẠT'
  FROM inspection_templates t
  CROSS JOIN (VALUES
    (1,  'Pháp lý',     'Văn bản thẩm duyệt, nghiệm thu về PCCC (nếu thuộc diện)',               'Luật PCCC và CNCH 2024', TRUE),
    (2,  'Pháp lý',     'Bảo hiểm cháy, nổ bắt buộc còn hiệu lực (nếu thuộc diện)',             'Nghị định 105/2025/NĐ-CP', FALSE),
    (3,  'Quản lý',     'Nội quy, quy định phân công nhiệm vụ PCCC và CNCH',                     'Nghị định 105/2025/NĐ-CP', FALSE),
    (4,  'Quản lý',     'Hồ sơ quản lý, theo dõi hoạt động PCCC và CNCH',                        'Nghị định 105/2025/NĐ-CP', FALSE),
    (5,  'Lực lượng',   'Đội PCCC và CNCH cơ sở được thành lập, huấn luyện (nếu thuộc diện)',    'Nghị định 105/2025/NĐ-CP', FALSE),
    (6,  'Lực lượng',   'Phương án chữa cháy, CNCH được phê duyệt và thực tập định kỳ',          'Nghị định 105/2025/NĐ-CP', FALSE),
    (7,  'Phương tiện', 'Phương tiện chữa cháy ban đầu đủ, đúng chủng loại, còn sử dụng được',   'TCVN 3890', TRUE),
    (8,  'Phương tiện', 'Hệ thống báo cháy tự động hoạt động, có kết nối truyền tin (nếu thuộc diện)', 'TCVN 5738', TRUE),
    (9,  'Phương tiện', 'Hệ thống chữa cháy tự động / bằng nước hoạt động bình thường',          'TCVN 7336; TCVN 3890', TRUE),
    (10, 'Thoát nạn',   'Lối thoát nạn, cầu thang, hành lang bảo đảm số lượng, kích thước, thông thoáng', 'QCVN 06', TRUE),
    (11, 'Thoát nạn',   'Chiếu sáng sự cố, chỉ dẫn thoát nạn hoạt động',                          'QCVN 06', FALSE),
    (12, 'Điện',        'Hệ thống điện, chống sét, nguồn nhiệt bảo đảm an toàn',                  'Luật PCCC và CNCH 2024', TRUE),
    (13, 'Giao thông',  'Đường, bãi đỗ cho xe chữa cháy; nguồn nước chữa cháy bảo đảm',           'QCVN 06', FALSE)
  ) AS v(order_no, group_name, content, legal_basis, is_critical)
 WHERE t.code = 'KT_CO_QUAN'
ON CONFLICT (template_id, order_no) DO NOTHING;
