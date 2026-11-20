const AppError = require('../utils/AppError');

// RBAC: cho qua nếu có ADMIN hoặc có ÍT NHẤT 1 trong các quyền yêu cầu. Dùng: authorize('finding:write')
module.exports = (...required) => (req, res, next) => {
  const u = req.user;
  if (!u) return next(AppError.unauthorized());
  if (u.roles.includes('ADMIN') || required.some((p) => u.permissions.includes(p))) return next();
  next(AppError.forbidden());
};
