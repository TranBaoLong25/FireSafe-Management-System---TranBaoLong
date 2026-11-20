const { crudController } = require('../utils/crud');

// Định nghĩa từng bảng 1 lần; cột "columns" là whitelist được phép ghi.
const EVIDENCE = 'evidence_urls';

exports.findings = crudController({
  table: 'findings', idColumn: 'finding_id', orderBy: 'detected_at DESC',
  columns: ['facility_id', 'source_type', 'source_id', 'description', 'severity', 'recommendation', 'detected_at', 'status', EVIDENCE],
  filterable: ['facility_id', 'status', 'severity', 'source_type'],
});

exports.violations = crudController({
  table: 'violations', idColumn: 'violation_id', orderBy: 'created_at DESC',
  columns: ['code', 'facility_id', 'finding_id', 'violation_type', 'description', 'legal_basis', 'severity', 'detected_date', 'status', EVIDENCE],
  filterable: ['facility_id', 'finding_id', 'status', 'severity'],
});

const penaltyCols = ['decision_no', 'decision_date', 'penalty_form', 'fine_amount', 'payment_status', 'file_url'];
exports.penalties = crudController({
  table: 'administrative_penalties', idColumn: 'penalty_id', orderBy: 'decision_date DESC',
  columns: ['violation_id', ...penaltyCols], filterable: ['violation_id', 'payment_status', 'penalty_form'],
});
// Route lồng: /violations/:parentId/penalties (dùng tên tham số khác :id để không bị ghi đè)
exports.violationPenalties = crudController({
  table: 'administrative_penalties', idColumn: 'penalty_id', orderBy: 'decision_date DESC',
  columns: penaltyCols, scope: (req) => ({ violation_id: req.params.parentId }),
});

exports.remediations = crudController({
  table: 'remediations', idColumn: 'remediation_id', orderBy: 'created_at DESC',
  columns: ['finding_id', 'violation_id', 'action_plan', 'responsible_user_id', 'planned_date', 'completed_date', 'result_description', EVIDENCE, 'verified_by', 'verified_at', 'status'],
  filterable: ['finding_id', 'violation_id', 'status', 'responsible_user_id'],
});

exports.incidents = crudController({
  table: 'incidents', idColumn: 'incident_id', orderBy: 'occurred_at DESC',
  columns: ['code', 'incident_type', 'facility_id', 'occurred_at', 'reported_at', 'reported_by', 'address', 'latitude', 'longitude', 'cause', 'description', 'burned_area', 'death_count', 'injury_count', 'rescued_count', 'property_damage', 'level', 'status'],
  filterable: ['incident_type', 'facility_id', 'status', 'level'],
});

const child = (table, idColumn, columns, orderBy) =>
  crudController({ table, idColumn, columns, orderBy, scope: (req) => ({ incident_id: req.params.parentId }) });
exports.responses = child('incident_responses', 'incident_response_id', ['unit_id', 'vehicle_count', 'personnel_count', 'arrived_at', 'extinguished_at', 'note'], 'arrived_at');
exports.investigations = child('incident_investigations', 'investigation_id', ['investigator_id', 'conclusion', 'responsibility', 'report_url', 'concluded_at'], 'concluded_at');
exports.attachments = child('incident_attachments', 'attachment_id', ['file_url', 'file_type', 'description', 'uploaded_by'], 'uploaded_at');

exports.layers = crudController({
  table: 'gis_layers', idColumn: 'layer_id', orderBy: 'code',
  columns: ['code', 'name', 'layer_type', 'source', 'style_config', 'is_visible_default', 'min_role'],
  filterable: ['source', 'layer_type'],
});

exports.resources = crudController({
  table: 'firefighting_resources', idColumn: 'resource_id', orderBy: 'name',
  columns: ['resource_type', 'name', 'unit_id', 'latitude', 'longitude', 'capacity', 'status'],
  filterable: ['resource_type', 'unit_id', 'status'],
});
