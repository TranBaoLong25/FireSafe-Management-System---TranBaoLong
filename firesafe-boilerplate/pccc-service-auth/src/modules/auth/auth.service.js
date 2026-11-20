const bcrypt = require('bcryptjs');
const db = require('../../config/db');
const env = require('../../config/env');
const AppError = require('../../utils/AppError');
const { signAccessToken, newRefreshToken, hashToken } = require('../../utils/tokens');

const MAX_FAILED = 5;          // sai quá 5 lần thì khóa
const LOCK_MINUTES = 15;

const audit = (client, { userId = null, action, resourceType = 'auth', resourceId = null, ip, requestId }) =>
  client.query(
    `INSERT INTO audit_logs (user_id, action, resource_type, resource_id, ip_address, request_id)
     VALUES ($1,$2,$3,$4,$5,$6)`, [userId, action, resourceType, resourceId, ip, requestId]);

async function loadRolesAndPermissions(client, userId) {
  const roles = await client.query(
    `SELECT DISTINCT r.code FROM user_roles ur JOIN roles r ON r.role_id = ur.role_id WHERE ur.user_id = $1`, [userId]);
  const perms = await client.query(
    `SELECT DISTINCT p.code FROM user_roles ur
       JOIN role_permissions rp ON rp.role_id = ur.role_id
       JOIN permissions p ON p.permission_id = rp.permission_id
      WHERE ur.user_id = $1`, [userId]);
  return { roles: roles.rows.map((r) => r.code), permissions: perms.rows.map((p) => p.code) };
}

async function issueTokens(client, user, meta) {
  const { roles, permissions } = await loadRolesAndPermissions(client, user.user_id);
  const accessToken = signAccessToken(user, roles, permissions);
  const refreshToken = newRefreshToken();
  await client.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, device_info, ip_address)
     VALUES ($1,$2, now() + ($3 || ' days')::interval, $4, $5)`,
    [user.user_id, hashToken(refreshToken), String(env.jwt.refreshExpiresDays), meta.device, meta.ip]);
  return { accessToken, refreshToken, expiresIn: env.jwt.accessExpiresIn, roles, permissions };
}

// Luồng khớp sequence diagram UC01 - Đăng nhập
async function login({ username, password }, meta) {
  if (!username || !password) throw AppError.badRequest('Thiếu username hoặc password');
  return db.tx(async (c) => {
    const { rows } = await c.query('SELECT * FROM users WHERE username = $1', [username]);
    const user = rows[0];
    const bad = () => AppError.unauthorized('Sai tên đăng nhập hoặc mật khẩu');

    // Lưu ý: trả {__fail} (không throw) để transaction vẫn COMMIT audit log / bộ đếm sai
    if (!user) {
      await audit(c, { action: 'LOGIN_FAILED', resourceId: username, ...meta });
      return { __fail: bad() };
    }
    if (user.status !== 'ACTIVE' || (user.locked_until && user.locked_until > new Date())) {
      await audit(c, { userId: user.user_id, action: 'LOGIN_FAILED', ...meta });
      return { __fail: new AppError(423, 'Tài khoản đang bị khóa hoặc ngừng hoạt động', 'LOCKED') };
    }
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      const failed = user.failed_login_count + 1;
      await c.query(
        `UPDATE users SET failed_login_count = $2,
           locked_until = CASE WHEN $2 >= $3 THEN now() + ($4 || ' minutes')::interval ELSE locked_until END
         WHERE user_id = $1`, [user.user_id, failed, MAX_FAILED, String(LOCK_MINUTES)]);
      await audit(c, { userId: user.user_id, action: 'LOGIN_FAILED', ...meta });
      return { __fail: bad() };
    }
    await c.query('UPDATE users SET failed_login_count = 0, locked_until = NULL, last_login_at = now() WHERE user_id = $1', [user.user_id]);
    const tokens = await issueTokens(c, user, meta);
    await audit(c, { userId: user.user_id, action: 'LOGIN_SUCCESS', ...meta });
    return tokens;
  }).then((r) => { if (r && r.__fail) throw r.__fail; return r; });
}

// Xoay vòng refresh token: token cũ bị thu hồi, cấp token mới
async function refresh(token, meta) {
  if (!token) throw AppError.badRequest('Thiếu refreshToken');
  return db.tx(async (c) => {
    const { rows } = await c.query(
      `SELECT rt.refresh_token_id, u.* FROM refresh_tokens rt JOIN users u ON u.user_id = rt.user_id
        WHERE rt.token_hash = $1 AND rt.revoked = FALSE AND rt.expires_at > now() AND u.status = 'ACTIVE'`, [hashToken(token)]);
    if (!rows.length) throw AppError.unauthorized('Refresh token không hợp lệ hoặc đã hết hạn');
    await c.query('UPDATE refresh_tokens SET revoked = TRUE, revoked_at = now() WHERE refresh_token_id = $1', [rows[0].refresh_token_id]);
    return issueTokens(c, rows[0], meta);
  });
}

async function logout(token, meta, userId) {
  if (token) {
    await db.query('UPDATE refresh_tokens SET revoked = TRUE, revoked_at = now() WHERE token_hash = $1 AND revoked = FALSE', [hashToken(token)]);
  }
  await audit(db, { userId, action: 'LOGOUT', ...meta });
}

async function me(userId) {
  const { rows } = await db.query(
    `SELECT user_id, username, full_name, email, phone, unit_id, status, last_login_at FROM users WHERE user_id = $1`, [userId]);
  if (!rows.length) throw AppError.notFound();
  return { ...rows[0], ...(await loadRolesAndPermissions(db, userId)) };
}

module.exports = { login, refresh, logout, me };
