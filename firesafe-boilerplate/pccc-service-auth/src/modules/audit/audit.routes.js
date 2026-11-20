const router = require('express').Router();
const authorize = require('../../middlewares/authorize');
const { crudController } = require('../../utils/crud');

const ctrl = crudController({ table: 'audit_logs', idColumn: 'audit_log_id', columns: [], filterable: ['user_id', 'action', 'resource_type'], orderBy: 'performed_at DESC' });
router.get('/', authorize('user:read'), ctrl.list);   // chỉ đọc, không cho sửa/xóa nhật ký
router.get('/:id', authorize('user:read'), ctrl.get);
module.exports = router;
