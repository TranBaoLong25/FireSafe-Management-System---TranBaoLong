-- ============================================================
-- Dữ liệu danh mục cho pccc-service-equipment
-- Chu kỳ bảo dưỡng (maintenance_cycle_days) là giá trị tham khảo để hệ thống tính ngày đến hạn,
-- nhóm điều chỉnh theo tiêu chuẩn và hướng dẫn của nhà sản xuất.
-- Chạy lại nhiều lần không lỗi (ON CONFLICT DO NOTHING).
-- ============================================================

-- Loại thiết bị PCCC
INSERT INTO equipment_types (code, name, category, maintenance_cycle_days, standard_ref) VALUES
  ('BINH_BOT',      'Bình chữa cháy bột',                          'BÌNH_CHỮA_CHÁY',  180, 'TCVN 7435-2'),
  ('BINH_CO2',      'Bình chữa cháy khí CO2',                      'BÌNH_CHỮA_CHÁY',  180, 'TCVN 7435-2'),
  ('BINH_FOAM',     'Bình chữa cháy bọt',                          'BÌNH_CHỮA_CHÁY',  180, 'TCVN 7435-2'),
  ('TU_BAO_CHAY',   'Tủ trung tâm báo cháy tự động',               'BÁO_CHÁY',        180, 'TCVN 5738'),
  ('DAU_BAO_KHOI',  'Đầu báo cháy khói',                           'BÁO_CHÁY',        180, 'TCVN 5738'),
  ('DAU_BAO_NHIET', 'Đầu báo cháy nhiệt',                          'BÁO_CHÁY',        180, 'TCVN 5738'),
  ('NUT_AN_BAO',    'Nút ấn báo cháy',                             'BÁO_CHÁY',        180, 'TCVN 5738'),
  ('CHUONG_DEN',    'Chuông, đèn báo cháy',                        'BÁO_CHÁY',        180, 'TCVN 5738'),
  ('SPRINKLER',     'Hệ thống chữa cháy tự động sprinkler',        'CHỮA_CHÁY_TỰ_ĐỘNG', 365, 'TCVN 7336'),
  ('HOP_VOI',       'Hộp vòi, họng nước chữa cháy vách tường',     'CHỮA_CHÁY_NƯỚC',  180, 'TCVN 3890'),
  ('MAY_BOM',       'Máy bơm chữa cháy',                           'CHỮA_CHÁY_NƯỚC',   90, 'TCVN 3890'),
  ('TRU_NUOC',      'Trụ nước chữa cháy ngoài nhà',                'CHỮA_CHÁY_NƯỚC',  180, 'TCVN 3890'),
  ('DEN_SU_CO',     'Đèn chiếu sáng sự cố',                        'THOÁT_NẠN',       180, 'TCVN 3890'),
  ('DEN_EXIT',      'Đèn chỉ dẫn thoát nạn (EXIT)',                'THOÁT_NẠN',       180, 'TCVN 3890'),
  ('MAT_NA',        'Mặt nạ lọc độc, khẩu trang thoát nạn',        'CỨU_NẠN',         365, 'TCVN 3890'),
  ('DUNG_CU_PHA_DO','Dụng cụ phá dỡ thô sơ (búa, xà beng, kìm)',   'CỨU_NẠN',         365, 'TCVN 3890')
ON CONFLICT (code) DO NOTHING;

-- Điều kiện an toàn PCCC đối với cơ sở (applicable_facility_types rỗng = mọi loại hình)
INSERT INTO safety_conditions (code, name, category, description, legal_basis) VALUES
  ('DK_NOI_QUY',     'Có nội quy, biển cấm, biển báo, sơ đồ, biển chỉ dẫn về PCCC và thoát nạn', 'QUẢN_LÝ',
     'Niêm yết ở nơi dễ thấy, phù hợp đặc điểm hoạt động của cơ sở.', 'Luật PCCC và CNCH 2024; Nghị định 105/2025/NĐ-CP'),
  ('DK_PHAN_CONG',   'Có quy định, phân công chức trách, nhiệm vụ PCCC và CNCH',                 'QUẢN_LÝ',
     'Văn bản phân công người chịu trách nhiệm PCCC tại cơ sở.', 'Luật PCCC và CNCH 2024; Nghị định 105/2025/NĐ-CP'),
  ('DK_DIEN',        'Hệ thống điện, chống sét, chống tĩnh điện bảo đảm an toàn PCCC',           'KỸ_THUẬT',
     'Thiết bị điện, nguồn nhiệt được lắp đặt, sử dụng đúng quy định.', 'Luật PCCC và CNCH 2024; Nghị định 105/2025/NĐ-CP'),
  ('DK_LUC_LUONG',   'Có Đội PCCC và CNCH cơ sở được huấn luyện nghiệp vụ',                      'LỰC_LƯỢNG',
     'Bắt buộc với cơ sở thuộc diện quản lý có từ 20 người thường xuyên làm việc trở lên.', 'Nghị định 105/2025/NĐ-CP'),
  ('DK_PHUONG_AN',   'Có phương án chữa cháy, CNCH của cơ sở được phê duyệt',                    'LỰC_LƯỢNG',
     'Theo mẫu PC06; tổ chức thực tập phương án định kỳ.', 'Nghị định 105/2025/NĐ-CP'),
  ('DK_THOAT_NAN',   'Lối thoát nạn, giao thông, nguồn nước chữa cháy bảo đảm',                  'KỸ_THUẬT',
     'Lối thoát nạn thông thoáng, không bị khóa, chiếm dụng; có đường cho xe chữa cháy.', 'Luật PCCC và CNCH 2024; QCVN 06'),
  ('DK_PHUONG_TIEN', 'Trang bị phương tiện PCCC và CNCH đủ số lượng, chủng loại, còn sử dụng được', 'KỸ_THUẬT',
     'Bình chữa cháy, báo cháy, chữa cháy tự động... được kiểm tra, bảo dưỡng định kỳ.', 'Luật PCCC và CNCH 2024; TCVN 3890'),
  ('DK_HO_SO',       'Có hồ sơ quản lý, theo dõi hoạt động PCCC và CNCH',                        'QUẢN_LÝ',
     'Lập và cập nhật hồ sơ theo quy định.', 'Nghị định 105/2025/NĐ-CP'),
  ('DK_THAM_DUYET',  'Có văn bản thẩm duyệt, nghiệm thu về PCCC (công trình thuộc diện)',         'PHÁP_LÝ',
     'Áp dụng với công trình thuộc diện thẩm duyệt thiết kế về PCCC.', 'Luật PCCC và CNCH 2024; Nghị định 105/2025/NĐ-CP'),
  ('DK_BAO_HIEM',    'Mua bảo hiểm cháy, nổ bắt buộc (cơ sở thuộc diện)',                        'PHÁP_LÝ',
     'Áp dụng với cơ sở có nguy hiểm về cháy, nổ thuộc diện bắt buộc.', 'Nghị định 105/2025/NĐ-CP')
ON CONFLICT (code) DO NOTHING;
