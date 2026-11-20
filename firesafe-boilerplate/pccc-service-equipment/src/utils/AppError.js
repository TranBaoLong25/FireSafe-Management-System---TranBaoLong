class AppError extends Error {
  constructor(status, message, code) {
    super(message);
    this.status = status;
    this.code = code;
  }
  static badRequest(msg = 'Dữ liệu không hợp lệ') { return new AppError(400, msg, 'BAD_REQUEST'); }
  static unauthorized(msg = 'Chưa đăng nhập hoặc token không hợp lệ') { return new AppError(401, msg, 'UNAUTHORIZED'); }
  static forbidden(msg = 'Không đủ quyền thực hiện') { return new AppError(403, msg, 'FORBIDDEN'); }
  static notFound(msg = 'Không tìm thấy dữ liệu') { return new AppError(404, msg, 'NOT_FOUND'); }
  static conflict(msg = 'Dữ liệu bị trùng hoặc ràng buộc') { return new AppError(409, msg, 'CONFLICT'); }
}
module.exports = AppError;
