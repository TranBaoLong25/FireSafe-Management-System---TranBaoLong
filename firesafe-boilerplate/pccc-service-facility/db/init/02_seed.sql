-- ============================================================
-- Dữ liệu danh mục cho pccc-service-facility
-- Căn cứ: Luật PCCC và CNCH 2024; Nghị định 105/2025/NĐ-CP (hiệu lực 01/7/2025).
-- Danh mục rút gọn để chạy hệ thống và demo; nhóm đối chiếu Phụ lục I, II của NĐ 105/2025 nếu cần đầy đủ.
-- Chạy lại nhiều lần không lỗi (ON CONFLICT DO NOTHING).
-- ============================================================

-- Loại hình cơ sở
INSERT INTO facility_types (code, name, facility_group, default_risk_level) VALUES
  ('CHUNG_CU',        'Nhà chung cư, nhà ở tập thể',                         'NHÀ_Ở',           'CAO'),
  ('NHA_O_KD',        'Nhà ở kết hợp sản xuất, kinh doanh',                  'NHÀ_Ở',           'TRUNG_BÌNH'),
  ('NHA_TRO',         'Nhà trọ, nhà cho thuê nhiều phòng',                   'NHÀ_Ở',           'TRUNG_BÌNH'),
  ('TRUONG_HOC',      'Nhà trẻ, trường học, cơ sở giáo dục',                 'GIÁO_DỤC',        'TRUNG_BÌNH'),
  ('BENH_VIEN',       'Bệnh viện, cơ sở khám chữa bệnh',                     'Y_TẾ',            'CAO'),
  ('CHO_TTTM',        'Chợ, trung tâm thương mại, siêu thị',                 'THƯƠNG_MẠI',      'CAO'),
  ('KHACH_SAN',       'Khách sạn, nhà nghỉ, cơ sở lưu trú',                  'DỊCH_VỤ',         'CAO'),
  ('KARAOKE_VUTRUONG','Karaoke, vũ trường, quán bar',                        'DỊCH_VỤ',         'CAO'),
  ('NHA_HANG',        'Nhà hàng, cơ sở ăn uống',                             'DỊCH_VỤ',         'TRUNG_BÌNH'),
  ('VAN_PHONG',       'Nhà làm việc, trụ sở cơ quan, văn phòng',             'CƠ_QUAN',         'THẤP'),
  ('NHA_XUONG',       'Nhà xưởng, cơ sở sản xuất',                           'SẢN_XUẤT',        'CAO'),
  ('KHO_HANG',        'Kho hàng hóa, vật tư',                                'KHO_BÃI',         'CAO'),
  ('CAY_XANG',        'Cửa hàng kinh doanh xăng dầu, khí đốt',               'XĂNG_DẦU_KHÍ',    'CAO'),
  ('BAI_XE',          'Gara, bãi đỗ xe',                                     'GIAO_THÔNG',      'TRUNG_BÌNH')
ON CONFLICT (code) DO NOTHING;

-- Loại tài liệu trong hồ sơ PCCC (applicable_facility_types rỗng = áp dụng mọi loại hình)
INSERT INTO document_types (code, name, is_required, has_expiry, applicable_facility_types) VALUES
  ('NOI_QUY_PCCC',     'Nội quy PCCC và CNCH, biển cấm, biển báo, sơ đồ chỉ dẫn', TRUE,  FALSE, '[]'),
  ('QD_PHAN_CONG',     'Quyết định phân công nhiệm vụ PCCC và CNCH',             TRUE,  FALSE, '[]'),
  ('VB_THAM_DUYET',    'Văn bản thẩm duyệt thiết kế về PCCC',                    FALSE, FALSE, '[]'),
  ('VB_NGHIEM_THU',    'Văn bản chấp thuận kết quả nghiệm thu về PCCC',          FALSE, FALSE, '[]'),
  ('PHUONG_AN_CC',     'Phương án chữa cháy, CNCH của cơ sở (mẫu PC06)',         TRUE,  FALSE, '[]'),
  ('QD_DOI_PCCC',      'Quyết định thành lập Đội PCCC và CNCH cơ sở',            FALSE, FALSE, '[]'),
  ('CN_HUAN_LUYEN',    'Chứng nhận huấn luyện nghiệp vụ PCCC và CNCH',           FALSE, TRUE,  '[]'),
  ('BAO_HIEM_CHAY_NO', 'Hợp đồng/Giấy chứng nhận bảo hiểm cháy, nổ bắt buộc',    FALSE, TRUE,  '[]'),
  ('KIEM_DINH_PT',     'Giấy chứng nhận kiểm định phương tiện PCCC',             FALSE, TRUE,  '[]'),
  ('BB_TU_KIEM_TRA',   'Biên bản tự kiểm tra về PCCC',                           TRUE,  FALSE, '[]'),
  ('SO_THEO_DOI',      'Sổ theo dõi phương tiện, hoạt động PCCC',                TRUE,  FALSE, '[]'),
  ('BB_KIEM_TRA_CA',   'Biên bản kiểm tra của cơ quan Công an',                  FALSE, FALSE, '[]')
ON CONFLICT (code) DO NOTHING;

-- Thẩm duyệt / nghiệm thu chỉ áp dụng cho loại hình có nguy cơ cao
UPDATE document_types d
   SET applicable_facility_types = (
     SELECT COALESCE(jsonb_agg(facility_type_id ORDER BY code), '[]'::jsonb)
       FROM facility_types WHERE default_risk_level = 'CAO')
 WHERE d.code IN ('VB_THAM_DUYET', 'VB_NGHIEM_THU')
   AND d.applicable_facility_types = '[]'::jsonb;
