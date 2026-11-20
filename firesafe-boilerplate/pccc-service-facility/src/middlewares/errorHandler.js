// Chuyển lỗi PostgreSQL sang HTTP status dễ hiểu
const PG = {
  '23505': [409, 'Dữ liệu đã tồn tại (trùng giá trị duy nhất)'],
  '23503': [409, 'Vi phạm khóa ngoại: dữ liệu liên quan không tồn tại hoặc đang được sử dụng'],
  '23502': [400, 'Thiếu trường bắt buộc'],
  '23514': [400, 'Giá trị không thỏa ràng buộc kiểm tra (CHECK)'],
  '22P02': [400, 'Sai định dạng dữ liệu (ví dụ UUID, số, ngày)'],
};

// eslint-disable-next-line no-unused-vars
module.exports = (err, req, res, next) => {
  let status = err.status || 500;
  let message = err.message || 'Lỗi hệ thống';
  if (err.code && PG[err.code]) [status, message] = PG[err.code];
  if (err.type === 'entity.parse.failed') { status = 400; message = 'JSON không hợp lệ'; }
  if (status >= 500) console.error('[error]', err);
  res.status(status).json({
    error: { code: err.code && !PG[err.code] ? err.code : undefined, message: status >= 500 ? 'Lỗi hệ thống' : message },
  });
};
