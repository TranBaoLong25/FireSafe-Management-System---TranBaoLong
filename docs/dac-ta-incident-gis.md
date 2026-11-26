# Đặc tả nghiệp vụ – vi phạm, sự cố, bản đồ, cảnh báo (UC07–UC10)

Task **T4-11** · Người làm: Trần Bảo Long (TV5) · Checklist 1.1: **#63**
Đọc kèm: `docs/incident-gis.md` (bảng dữ liệu, API). Phần đánh dấu **[Lệch]** là chỗ code bản 1.1 khác đặc tả Confluence, cần chốt với Mentor.

## Vai trò

| Vai trò | Trong UC07–UC10 làm gì |
|---|---|
| ADMIN | cấu hình quy tắc cảnh báo, lớp bản đồ; xuất báo cáo đã lập |
| MANAGER (lãnh đạo, quản lý) | lập báo cáo, mở lại sự cố đã đóng, nhận cảnh báo sự cố và quá hạn |
| INSPECTOR (cán bộ kiểm tra) | ghi nhận tồn tại, vi phạm, xử phạt; xác nhận khắc phục; ghi nhận sự cố |
| FACILITY_OWNER (chủ cơ sở) | xem tồn tại / vi phạm của cơ sở mình, báo đã khắc phục, nhận cảnh báo |
| VIEWER | chỉ xem |

## UC07 – Tồn tại, kiến nghị, vi phạm, khắc phục

**Luồng chính**

1. Sau buổi kiểm tra (UC05 tự kiểm tra hoặc UC06 Công an kiểm tra), cán bộ **ghi nhận tồn tại**: cơ sở nào, mô tả, mức độ (nhẹ / trung bình / nghiêm trọng), ảnh minh chứng, nguồn là phiếu nào.
2. Cán bộ **lập kiến nghị khắc phục** kèm thời hạn. Thời hạn không được trước hôm nay.
3. Chủ cơ sở **khắc phục** rồi báo kết quả kèm minh chứng → chờ xác minh.
4. Cán bộ **xác minh**: đạt → đã khắc phục; không đạt → trả về, ghi lý do, cơ sở làm lại.
5. Quá thời hạn mà chưa khắc phục → hệ thống tự chuyển **quá hạn** và cảnh báo cán bộ, quản lý.
6. Tồn tại nghiêm trọng hoặc quá hạn → **chuyển xử lý vi phạm**: lập vi phạm (hành vi, căn cứ pháp lý) → **quyết định xử phạt** (cảnh cáo / phạt tiền / đình chỉ, số quyết định, số tiền, tình trạng nộp phạt). Có xử phạt thì vi phạm chuyển "đang xử lý"; khắc phục được xác nhận thì vi phạm "đã xử lý".
7. Cơ sở xin **gia hạn**: cán bộ duyệt, lưu lịch sử gia hạn và lý do.

**Trạng thái khắc phục theo đặc tả:** Mới ghi nhận → Chờ khắc phục → Chờ xác minh → Đã khắc phục / Quá hạn / Chuyển xử lý vi phạm.

**Quy tắc**
- Chủ cơ sở chỉ thấy tồn tại, vi phạm của cơ sở mình.
- Hồ sơ vi phạm đã duyệt thì không được xóa.
- Mọi lần đổi trạng thái đều ghi nhật ký (ai, lúc nào).

**[Lệch]** Code 1.1 tách 2 bảng trạng thái: tồn tại (MỚI, ĐANG_XỬ_LÝ, ĐÃ_KHẮC_PHỤC, QUÁ_HẠN) và khắc phục (CHỜ, ĐANG_THỰC_HIỆN, CHỜ_XÁC_NHẬN, HOÀN_THÀNH); chưa có bảng kiến nghị, chưa có gia hạn, vi phạm đã duyệt vẫn xóa được.

## UC08 – Sự cố cháy, nổ, cứu nạn cứu hộ

**Luồng chính**

1. **Tiếp nhận** sự cố: loại (cháy / nổ / CNCH / khác), thời điểm xảy ra, địa chỉ, tọa độ, cơ sở liên quan (nếu có), mức độ (loại và mức độ lấy từ danh mục dùng chung UC01.06).
2. Hệ thống **cảnh báo trùng** nếu đã có sự cố gần cùng vị trí, gần cùng thời gian.
3. Sự cố mới → **cảnh báo ngay** cho quản lý, cán bộ; chủ cơ sở liên quan được báo tin.
4. **Điều lực lượng**: đơn vị, số xe, số người, giờ đến, giờ dập tắt → sự cố chuyển "đang xử lý".
5. Ghi **diễn biến** theo thời gian; đính kèm ảnh, tài liệu.
6. **Thiệt hại**: diện tích cháy, người chết, bị thương, cứu được, thiệt hại tài sản – phải được **xác nhận trước khi đóng** sự cố.
7. **Điều tra, kết luận** nguyên nhân, trách nhiệm → đóng sự cố.
8. Sự cố đã đóng không sửa được; chỉ **Manager mở lại** kèm lý do.

**Trạng thái (code 1.1):** TIẾP_NHẬN → ĐANG_XỬ_LÝ → ĐÃ_DẬP_TẮT → ĐÃ_KẾT_LUẬN.

**[Lệch]** Code chưa có diễn biến, xác nhận thiệt hại, cảnh báo trùng, mở lại kèm lý do; loại sự cố đang cố định trong CSDL thay vì lấy từ danh mục.

## UC09 – Giám sát cơ sở trên bản đồ GIS

1. Bản đồ hiện các lớp: cơ sở PCCC, sự cố, trụ nước, đội PCCC; bật / tắt từng lớp; lớp hiện theo vai trò (`min_role`).
2. Cơ sở, sự cố, nguồn nước có tọa độ thì **tự lên bản đồ** khi thêm / sửa / xóa.
3. **Tìm cơ sở** theo tên; **lọc** theo địa bàn và trạng thái (có vi phạm, có sự cố...).
4. Bấm vào điểm → xem thông tin tóm tắt và đi tới chi tiết.
5. Danh sách **cơ sở thiếu tọa độ** cần bổ sung; nguồn nước kèm ngày cập nhật.
6. Manager / Inspector chỉ thấy cơ sở thuộc **địa bàn được giao**.
7. Bản đồ lỗi (mất mạng tile) thì hiện **danh sách thay thế**.

**[Lệch]** Code 1.1 chỉ lọc theo vùng nhìn (bbox); chưa lọc địa bàn / trạng thái, chưa có danh sách thiếu tọa độ, chưa phân quyền theo địa bàn.

## UC10 – Báo cáo và cảnh báo nghiệp vụ

1. **Dashboard** số liệu chính.
2. **Thống kê** 4 loại: cơ sở, hoạt động kiểm tra, tồn tại – vi phạm, tình hình khắc phục; lấy số liệu từ các service, service nào lỗi thì vẫn hiện phần còn lại.
3. Manager **lập báo cáo** theo kỳ (tháng / quý / năm / tùy chọn), **xuất Excel / PDF**; Admin chỉ xuất báo cáo đã lập.
4. **Cảnh báo tự động** theo quy tắc (bật / tắt, số ngày báo trước, vai trò nhận): tài liệu sắp hết hạn, thiết bị tới hạn bảo dưỡng, sắp tới lịch kiểm tra, khắc phục quá hạn, sự cố mới. Không gửi trùng; chủ cơ sở chỉ nhận cảnh báo của cơ sở mình.
5. **Notification Service (UC10.09)** gửi trong ứng dụng và email; ghi trạng thái gửi, gửi lỗi thì thử lại.

**[Lệch]** Code 1.1 mới có 2 loại thống kê (vi phạm, sự cố), xuất CSV, chưa có dashboard, chưa gửi email.

## Câu hỏi cho Mentor

1. UC07: tồn tại và kiến nghị là **2 đối tượng riêng** (1 tồn tại nhiều kiến nghị) hay gộp làm một? 6 trạng thái khắc phục áp cho tồn tại hay cho kiến nghị?
2. UC07: khi nào tồn tại **chuyển xử lý vi phạm** – cán bộ tự chọn, hay tự động khi quá hạn / mức nghiêm trọng?
3. UC07: **gia hạn** được mấy lần, ai duyệt (Inspector hay Manager)? Có giới hạn số ngày không?
4. UC07: hồ sơ vi phạm "đã duyệt" là sau bước nào – có quyết định xử phạt, hay Manager duyệt riêng?
5. UC07: xử phạt có cần theo dõi **nộp phạt** (hạn nộp, quá hạn) không, hay chỉ lưu quyết định?
6. UC08: tiêu chí **sự cố trùng** cụ thể: bán kính bao nhiêu mét, cách nhau bao nhiêu phút?
7. UC08: các trạng thái chính thức của sự cố là gì? "Đóng" tương ứng với "đã kết luận" hay có trạng thái riêng?
8. UC08: ai **xác nhận thiệt hại** – cán bộ ghi nhận hay Manager?
9. UC08: chủ cơ sở **báo tin sự cố** trực tiếp trên hệ thống được không, hay chỉ cán bộ tiếp nhận?
10. UC09: "địa bàn được giao" của Manager / Inspector lưu ở đâu – theo đơn vị (units) hay danh mục địa bàn riêng?
11. UC09: có cần vẽ vùng (polygon) như ranh giới địa bàn, hay chỉ điểm?
12. UC10: báo cáo có cần **mẫu cố định** theo biểu mẫu của ngành không? Xuất PDF có bắt buộc ở giai đoạn này?
13. UC10: Notification Service là **service riêng** (CSDL riêng) hay để trong incident-gis như hiện tại?
14. UC10: kênh gửi bắt buộc là gì – trong ứng dụng + email là đủ, hay cần SMS / push?
