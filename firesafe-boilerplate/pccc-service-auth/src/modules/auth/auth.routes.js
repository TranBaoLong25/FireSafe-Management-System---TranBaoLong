const router = require('express').Router();
const authenticate = require('../../middlewares/authenticate');
const c = require('./auth.controller');

router.post('/login', c.login);
router.post('/refresh', c.refresh);
router.post('/logout', authenticate, c.logout);
router.get('/me', authenticate, c.me);

module.exports = router;
