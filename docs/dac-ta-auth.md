# Đặc tả nghiệp vụ – Quản trị hệ thống và người dùng (UC01)

Task **T4-13** · Người làm: Huỳnh Thúy Hằng (TV1) · Checklist 1.1: **#63**
Đọc kèm: `docs/auth.md` (bảng dữ liệu, API). Phần **[Lệch]** là chỗ code bản 1.1 khác đặc tả Confluence, cần chốt với Mentor.

## Vai trò

| Vai trò | Ý nghĩa |
|---|---|
| ADMIN | Quản trị hệ thống: tài khoản, đơn vị, vai trò, quyền, danh mục, cấu hình |
| MANAGER | Lãnh đạo, quản lý: xem tất cả, duyệt kế hoạch kiểm tra, lập báo cáo |
| INSPECTOR | Cán bộ kiểm tra: nghiệp vụ kiểm tra, vi phạm, sự cố |
| FACILITY_OWNER | Chủ cơ sở / người đại diện: chỉ dữ liệu cơ sở của mình |
| VIEWER | Chỉ xem |

## UC01.01 – Đăng nhập, đăng xuất

1. Người dùng nhập tên đăng nhập, mật khẩu.
2. Tài khoản bị khóa hoặc ngừng hoạt động → từ chối, báo rõ lý do.
3. Sai mật khẩu → tăng bộ đếm; sai **5 lần** liên tiếp → khóa **15 phút**. Đăng nhập đúng thì bộ đếm về 0.
4. Đúng → cấp access token (ngắn hạn) và refresh token (dài hạn), trả vai trò và quyền để giao diện hiện menu phù hợp.
5. Hết hạn access token → dùng refresh token lấy token mới; hết phiên → tự đăng xuất.
6. Đăng xuất → thu hồi refresh token của thiết bị đó.
7. Mọi lần đăng nhập thành công / thất bại đều ghi nhật ký (người, IP, thời điểm).

## UC01.02 – Quản lý tài khoản

- Admin tạo, sửa, khóa / mở khóa, đặt lại mật khẩu tài khoản; gắn tài khoản vào đơn vị.
- Tên đăng nhập, email không trùng; mật khẩu đủ mạnh; chỉ lưu bản băm (bcrypt).
- Tài khoản **đã có dữ liệu** thì chỉ khóa, không xóa.
- Admin **không tự khóa** chính mình.

**[Lệch]** Code đang cho xóa thật tài khoản; chưa chặn Admin tự khóa mình.

## UC01.03 – Quản lý đơn vị

- Đơn vị dạng cây: Công an tỉnh → phòng → đội; có mã tỉnh / huyện / xã để gắn địa bàn.
- Không cho đơn vị làm cha của chính nó.

## UC01.04 – Vai trò và phân quyền

- Quyền dạng `<chức năng>:<thao tác>` (read, write, approve). Vai trò = tập quyền.
- Gán vai trò cho người dùng có thể kèm **phạm vi**: chủ cơ sở gắn với cơ sở của mình; cán bộ gắn với địa bàn được giao.
- Không được làm mất quyền của **Admin cuối cùng**.
- Vô hiệu một vai trò đang gán cho người dùng → hệ thống cảnh báo trước.
- Vai trò hệ thống (5 vai trò mặc định) không xóa được.

**[Lệch]** Code chưa chặn Admin cuối cùng, chưa cảnh báo khi vô hiệu vai trò đang dùng; phạm vi theo địa bàn chưa dùng tới (chỉ có phạm vi cơ sở cho chủ cơ sở ở bản 1.1).

## UC01.05 – Đổi mật khẩu, quên mật khẩu

- Người dùng tự đổi mật khẩu (nhập mật khẩu cũ); sau khi đổi, các thiết bị khác phải đăng nhập lại.
- Quên mật khẩu → gửi link đặt lại qua email, link dùng 1 lần, có hạn.
- Admin đặt mật khẩu mới cho người dùng.

## UC01.06 – Danh mục dùng chung

- Admin quản lý các danh mục dùng chung cho cả hệ thống: loại sự cố, mức độ sự cố, địa bàn, ...
- Danh mục đã được dữ liệu khác dùng thì chỉ **ngừng sử dụng**, không xóa.

**[Lệch]** Chưa có. Loại, mức độ sự cố đang là giá trị cố định trong CSDL incident-gis.

## UC01.07 – Nhật ký hoạt động

- Ghi lại: ai, làm gì, trên đối tượng nào, giá trị trước / sau, IP, thời điểm.
- Chỉ xem, không sửa / xóa; lọc theo người, hành động, ngày.

## UC01.08 – Cấu hình hệ thống

- Admin cấu hình: số lần đăng nhập sai tối đa, thời gian khóa, thời gian hết phiên, ...

**[Lệch]** Các giá trị này đang viết cứng trong code (5 lần, 15 phút, token 15 phút).

## Câu hỏi cho Mentor

1. Danh mục dùng chung (UC01.06) gồm **những danh mục nào** cụ thể? Ai được thêm – chỉ Admin hay cả Manager?
2. Địa bàn là **danh mục riêng** hay dùng luôn cây đơn vị (units) với mã tỉnh / huyện / xã?
3. Cán bộ (Inspector, Manager) được giao **một hay nhiều địa bàn**? Đơn vị cấp trên có tự thấy dữ liệu của đơn vị cấp dưới không?
4. Một người có được giữ **nhiều vai trò** cùng lúc không (vd vừa Inspector vừa Manager)?
5. Chủ cơ sở **tự đăng ký** tài khoản được không, hay Admin / cán bộ tạo rồi cấp?
6. Một chủ cơ sở quản lý **nhiều cơ sở** thì dùng 1 tài khoản hay nhiều?
7. Quy định **độ mạnh mật khẩu** (độ dài, ký tự đặc biệt) và có bắt buộc đổi mật khẩu định kỳ không?
8. Tài khoản khóa do sai mật khẩu: **tự mở** sau 15 phút hay phải Admin mở? Số lần và thời gian có cần cấu hình theo đơn vị không?
9. Thời gian hết phiên bao lâu? Có cần **đăng nhập một thiết bị** tại một thời điểm không?
10. Quên mật khẩu gửi qua **email**, hay cần cả SMS? Có SMTP của trường / đơn vị để dùng không?
11. Nhật ký cần lưu **bao lâu**? Có cần xuất nhật ký ra file không?
12. Vai trò, quyền có cho Admin **tạo mới** không, hay chỉ dùng 5 vai trò cố định?
