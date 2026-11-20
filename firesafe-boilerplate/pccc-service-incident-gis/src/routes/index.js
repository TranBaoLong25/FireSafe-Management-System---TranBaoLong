const router = require('express').Router();
const authenticate = require('../middlewares/authenticate');
const { crudRouter } = require('../utils/crud');
const m = require('../modules/modules');

router.use(authenticate);

// UC07
router.use('/findings', crudRouter(m.findings, 'finding'));
const violations = crudRouter(m.violations, 'violation');
violations.use('/:parentId/penalties', crudRouter(m.violationPenalties, 'penalty'));      // /violations/:id/penalties
router.use('/violations', violations);
router.use('/penalties', crudRouter(m.penalties, 'penalty'));
router.use('/remediations', crudRouter(m.remediations, 'remediation'));
// TODO UC07: PUT /remediations/:id/verify -> cập nhật Remediation HOÀN_THÀNH + Finding/Violation (làm trong 1 transaction db.tx)

// UC08
const incidents = crudRouter(m.incidents, 'incident');
incidents.use('/:parentId/responses', crudRouter(m.responses, 'incident'));               // /incidents/:id/responses
incidents.use('/:parentId/investigations', crudRouter(m.investigations, 'incident'));
incidents.use('/:parentId/attachments', crudRouter(m.attachments, 'incident'));
router.use('/incidents', incidents);

// UC09
router.use('/gis', require('../modules/gis/gis.routes'));

module.exports = router;
