const router = require('express').Router();
const bcrypt = require('bcryptjs');
const db = require('../../config/db');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');
const authorize = require('../../middlewares/authorize');
const { crudController, pick } = require('../../utils/crud');

const SAFE = 'user_id, username, full_name, email, phone, id_number, unit_id, status, last_login_at, created_at, updated_at';
const base = crudController({
  table: 'users', idColumn: 'user_id', select: SAFE, orderBy: 'created_at DESC',
  columns: ['full_name', 'email', 'phone', 'id_number', 'unit_id', 'status'],
  filterable: ['unit_id', 'status'],
});

router.get('/', authorize('user:read'), base.list);
router.get('/:id', authorize('user:read'), base.get);

router.post('/', authorize('user:write'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  if (!b.username || !b.password || !b.full_name) throw AppError.badRequest('Cần username, password, full_name');
  if (String(b.password).length < 8) throw AppError.badRequest('Mật khẩu tối thiểu 8 ký tự');
  const hash = await bcrypt.hash(b.password, 10);
  const { rows } = await db.query(
    `INSERT INTO users (username, password_hash, full_name, email, phone, id_number, unit_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING ${SAFE}`,
    [b.username, hash, b.full_name, b.email || null, b.phone || null, b.id_number || null, b.unit_id || null]);
  res.status(201).json({ data: rows[0] });
}));

router.put('/:id', authorize('user:write'), base.update);
router.delete('/:id', authorize('user:write'), base.remove);

// Gán / gỡ vai trò cho người dùng
router.post('/:id/roles', authorize('user:write'), asyncHandler(async (req, res) => {
  const b = pick(req.body || {}, ['role_id', 'scope_type', 'scope_id']);
  if (!b.role_id) throw AppError.badRequest('Cần role_id');
  const { rows } = await db.query(
    `INSERT INTO user_roles (user_id, role_id, scope_type, scope_id, assigned_by) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [req.params.id, b.role_id, b.scope_type || null, b.scope_id || null, req.user.id]);
  await db.query(`INSERT INTO audit_logs (user_id, action, resource_type, resource_id, new_value) VALUES ($1,'ASSIGN_ROLE','user',$2,$3)`,
    [req.user.id, req.params.id, JSON.stringify(rows[0])]);
  res.status(201).json({ data: rows[0] });
}));
router.delete('/:id/roles/:userRoleId', authorize('user:write'), asyncHandler(async (req, res) => {
  const r = await db.query('DELETE FROM user_roles WHERE user_role_id = $1 AND user_id = $2', [req.params.userRoleId, req.params.id]);
  if (!r.rowCount) throw AppError.notFound();
  res.status(204).end();
}));

module.exports = router;
