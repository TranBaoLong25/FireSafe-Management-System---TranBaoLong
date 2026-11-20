const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');

const signAccessToken = (user, roles, permissions) =>
  jwt.sign({ sub: user.user_id, username: user.username, roles, permissions }, env.jwt.secret, {
    expiresIn: env.jwt.accessExpiresIn,
  });

// Refresh token là chuỗi ngẫu nhiên; CSDL chỉ lưu SHA-256 (token_hash)
const newRefreshToken = () => crypto.randomBytes(48).toString('hex');
const hashToken = (t) => crypto.createHash('sha256').update(t).digest('hex');

module.exports = { signAccessToken, newRefreshToken, hashToken };
