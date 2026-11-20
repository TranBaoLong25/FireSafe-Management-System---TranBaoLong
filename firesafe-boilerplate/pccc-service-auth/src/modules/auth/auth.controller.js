const asyncHandler = require('../../utils/asyncHandler');
const svc = require('./auth.service');

const meta = (req) => ({ ip: req.ip, device: req.headers['user-agent'], requestId: req.headers['x-request-id'] });

exports.login = asyncHandler(async (req, res) => res.json({ data: await svc.login(req.body || {}, meta(req)) }));
exports.refresh = asyncHandler(async (req, res) => res.json({ data: await svc.refresh((req.body || {}).refreshToken, meta(req)) }));
exports.logout = asyncHandler(async (req, res) => { await svc.logout((req.body || {}).refreshToken, meta(req), req.user.id); res.status(204).end(); });
exports.me = asyncHandler(async (req, res) => res.json({ data: await svc.me(req.user.id) }));
