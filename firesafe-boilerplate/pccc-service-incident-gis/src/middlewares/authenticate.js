const jwt = require('jsonwebtoken');
const env = require('../config/env');
const AppError = require('../utils/AppError');

// Xác thực JWT do pccc-service-auth cấp. Payload: { sub, username, roles: [], permissions: [] }
module.exports = (req, res, next) => {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');
  if (type !== 'Bearer' || !token) return next(AppError.unauthorized());
  try {
    const p = jwt.verify(token, env.jwt.secret);
    req.user = { id: p.sub, username: p.username, roles: p.roles || [], permissions: p.permissions || [] };
    next();
  } catch (e) {
    next(AppError.unauthorized(e.name === 'TokenExpiredError' ? 'Token đã hết hạn' : undefined));
  }
};
