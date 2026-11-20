const router = require('express').Router();
const authenticate = require('../middlewares/authenticate');

router.use('/auth', require('../modules/auth/auth.routes'));       // login/refresh công khai

// Các route dưới đây yêu cầu đăng nhập
router.use(authenticate);
router.use('/users', require('../modules/users/users.routes'));
router.use('/units', require('../modules/units/units.routes'));
router.use('/audit-logs', require('../modules/audit/audit.routes'));
router.use('/', require('../modules/rbac/rbac.routes'));           // /roles, /permissions

module.exports = router;
