const router = require('express').Router();
const authenticate = require('../middlewares/authenticate');

router.use(authenticate);

// TODO: gắn các module của service này tại đây, ví dụ:
//   const { crudController, crudRouter } = require('../utils/crud');
//   const ctrl = crudController({ table: 'ten_bang', idColumn: 'ten_id', columns: [...], filterable: [...] });
//   router.use('/ten-bang', crudRouter(ctrl, 'ten_module'));   // quyền: ten_module:read / ten_module:write

module.exports = router;
