const router = require('express').Router();
const authorize = require('../../middlewares/authorize');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');
const db = require('../../config/db');
const { crudController, crudRouter } = require('../../utils/crud');

const roles = crudController({ table: 'roles', idColumn: 'role_id', columns: ['code', 'name', 'description'], orderBy: 'code' });
const perms = crudController({ table: 'permissions', idColumn: 'permission_id', columns: ['code', 'name', 'module', 'action'], filterable: ['module'], orderBy: 'code' });

const rolesRouter = crudRouter(roles, 'role');
// Quyền của 1 vai trò + gán/gỡ quyền
rolesRouter.get('/:id/permissions', authorize('role:read'), asyncHandler(async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.* FROM role_permissions rp JOIN permissions p ON p.permission_id = rp.permission_id WHERE rp.role_id = $1 ORDER BY p.code`, [req.params.id]);
  res.json({ data: rows });
}));
rolesRouter.post('/:id/permissions', authorize('role:write'), asyncHandler(async (req, res) => {
  const { permission_id: pid } = req.body || {};
  if (!pid) throw AppError.badRequest('Cần permission_id');
  await db.query('INSERT INTO role_permissions (role_id, permission_id) VALUES ($1,$2) ON CONFLICT DO NOTHING', [req.params.id, pid]);
  res.status(201).json({ data: { role_id: req.params.id, permission_id: pid } });
}));
rolesRouter.delete('/:id/permissions/:pid', authorize('role:write'), asyncHandler(async (req, res) => {
  await db.query('DELETE FROM role_permissions WHERE role_id = $1 AND permission_id = $2', [req.params.id, req.params.pid]);
  res.status(204).end();
}));

router.use('/roles', rolesRouter);
router.use('/permissions', crudRouter(perms, 'permission'));
module.exports = router;
