const router = require('express').Router();
const db = require('../../config/db');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');
const authorize = require('../../middlewares/authorize');
const { crudRouter, pick } = require('../../utils/crud');
const m = require('../modules');

// /gis/layers  (CRUD lớp bản đồ)
router.use('/layers', crudRouter(m.layers, 'gis'));

// GET /gis/layers/:id/features?bbox=minLng,minLat,maxLng,maxLat  -> GeoJSON FeatureCollection
router.get('/layers/:id/features', authorize('gis:read'), asyncHandler(async (req, res) => {
  const params = [req.params.id];
  let bboxSql = '';
  if (req.query.bbox) {
    const b = String(req.query.bbox).split(',').map(Number);
    if (b.length !== 4 || b.some(Number.isNaN)) throw AppError.badRequest('bbox phải dạng minLng,minLat,maxLng,maxLat');
    params.push(...b);
    bboxSql = 'AND geometry && ST_MakeEnvelope($2, $3, $4, $5, 4326)';
  }
  const { rows } = await db.query(
    `SELECT feature_id, ref_type, ref_id, name, properties, ST_AsGeoJSON(geometry)::json AS geometry
       FROM gis_features WHERE layer_id = $1 ${bboxSql} LIMIT 5000`, params);
  res.json({
    type: 'FeatureCollection',
    features: rows.map((r) => ({
      type: 'Feature', id: r.feature_id, geometry: r.geometry,
      properties: { ...r.properties, name: r.name, ref_type: r.ref_type, ref_id: r.ref_id },
    })),
  });
}));

// GET /gis/features/:id
router.get('/features/:id', authorize('gis:read'), asyncHandler(async (req, res) => {
  const { rows } = await db.query(
    `SELECT feature_id, layer_id, ref_type, ref_id, name, properties, ST_AsGeoJSON(geometry)::json AS geometry
       FROM gis_features WHERE feature_id = $1`, [req.params.id]);
  if (!rows.length) throw AppError.notFound();
  res.json({ data: rows[0] });
}));

// POST /gis/features  { layer_id, ref_type, ref_id, name, geometry: <GeoJSON geometry>, properties }
router.post('/features', authorize('gis:write'), asyncHandler(async (req, res) => {
  const b = pick(req.body || {}, ['layer_id', 'ref_type', 'ref_id', 'name', 'geometry', 'properties']);
  if (!b.layer_id || !b.geometry) throw AppError.badRequest('Cần layer_id và geometry (GeoJSON)');
  const { rows } = await db.query(
    `INSERT INTO gis_features (layer_id, ref_type, ref_id, name, geometry, properties)
     VALUES ($1,$2,$3,$4, ST_SetSRID(ST_GeomFromGeoJSON($5), 4326), COALESCE($6::jsonb, '{}'::jsonb))
     RETURNING feature_id, layer_id, ref_type, ref_id, name`,
    [b.layer_id, b.ref_type || null, b.ref_id || null, b.name || null, JSON.stringify(b.geometry), b.properties ? JSON.stringify(b.properties) : null]);
  res.status(201).json({ data: rows[0] });
}));
router.delete('/features/:id', authorize('gis:write'), asyncHandler(async (req, res) => {
  const r = await db.query('DELETE FROM gis_features WHERE feature_id = $1', [req.params.id]);
  if (!r.rowCount) throw AppError.notFound();
  res.status(204).end();
}));

// /gis/resources  (tài nguyên chữa cháy)
router.use('/resources', crudRouter(m.resources, 'resource'));

module.exports = router;
