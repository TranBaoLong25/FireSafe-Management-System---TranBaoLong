const express = require('express');
const db = require('../config/db');
const AppError = require('./AppError');
const asyncHandler = require('./asyncHandler');
const authorize = require('../middlewares/authorize');

// pg biến mảng JS thành mảng PostgreSQL => với cột JSONB phải chuyển object/array thành chuỗi JSON
const ser = (v) => (v !== null && typeof v === 'object' && !(v instanceof Date) ? JSON.stringify(v) : v);

const pick = (src, cols) =>
  Object.fromEntries(cols.filter((c) => src[c] !== undefined).map((c) => [c, src[c]]));

/**
 * Sinh controller CRUD cho 1 bảng (tên bảng/cột lấy từ code, KHÔNG lấy từ người dùng => an toàn SQL injection).
 * @param {object} o
 *  table, idColumn   : tên bảng, cột khóa chính
 *  columns           : cột cho phép ghi (whitelist)
 *  filterable        : cột cho phép lọc bằng query ?cot=giatri
 *  orderBy           : mệnh đề ORDER BY cố định
 *  select            : danh sách cột trả về (mặc định *)
 *  scope(req)        : trả {cot: giatri} ép buộc (dùng cho route lồng: /incidents/:id/responses)
 */
function crudController({ table, idColumn, columns, filterable = [], orderBy, select = '*', scope }) {
  const order = orderBy || idColumn;
  const scoped = (req) => (scope ? scope(req) : {});

  const whereOf = (filters, params, startAt = 0) =>
    Object.entries(filters).map(([k, v]) => { params.push(v); return `${k} = $${startAt + params.length}`; });

  return {
    list: asyncHandler(async (req, res) => {
      const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
      const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 200);
      const params = [];
      const where = whereOf({ ...pick(req.query, filterable), ...scoped(req) }, params);
      const w = where.length ? `WHERE ${where.join(' AND ')}` : '';
      const total = (await db.query(`SELECT COUNT(*)::int AS n FROM ${table} ${w}`, params)).rows[0].n;
      const { rows } = await db.query(
        `SELECT ${select} FROM ${table} ${w} ORDER BY ${order} LIMIT ${limit} OFFSET ${(page - 1) * limit}`, params);
      res.json({ data: rows, meta: { page, limit, total } });
    }),

    get: asyncHandler(async (req, res) => {
      const params = [req.params.id];
      const where = [`${idColumn} = $1`, ...whereOf(scoped(req), params, 0)];
      const { rows } = await db.query(`SELECT ${select} FROM ${table} WHERE ${where.join(' AND ')}`, params);
      if (!rows.length) throw AppError.notFound();
      res.json({ data: rows[0] });
    }),

    create: asyncHandler(async (req, res) => {
      const data = { ...pick(req.body || {}, columns), ...scoped(req) };
      const keys = Object.keys(data);
      if (!keys.length) throw AppError.badRequest('Không có trường dữ liệu hợp lệ');
      const { rows } = await db.query(
        `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${keys.map((_, i) => `$${i + 1}`).join(', ')}) RETURNING ${select}`,
        keys.map((k) => ser(data[k])));
      res.status(201).json({ data: rows[0] });
    }),

    update: asyncHandler(async (req, res) => {
      const data = pick(req.body || {}, columns);
      const keys = Object.keys(data);
      if (!keys.length) throw AppError.badRequest('Không có trường dữ liệu hợp lệ');
      const params = keys.map((k) => ser(data[k]));
      params.push(req.params.id);
      const where = [`${idColumn} = $${params.length}`, ...whereOf(scoped(req), params, 0)];
      const { rows } = await db.query(
        `UPDATE ${table} SET ${keys.map((k, i) => `${k} = $${i + 1}`).join(', ')} WHERE ${where.join(' AND ')} RETURNING ${select}`, params);
      if (!rows.length) throw AppError.notFound();
      res.json({ data: rows[0] });
    }),

    remove: asyncHandler(async (req, res) => {
      const params = [req.params.id];
      const where = [`${idColumn} = $1`, ...whereOf(scoped(req), params, 0)];
      const r = await db.query(`DELETE FROM ${table} WHERE ${where.join(' AND ')}`, params);
      if (!r.rowCount) throw AppError.notFound();
      res.status(204).end();
    }),
  };
}

/** Gắn 5 route CRUD vào router, phân quyền theo `${perm}:read` / `${perm}:write`. */
function crudRouter(ctrl, perm, { only } = {}) {
  const r = express.Router({ mergeParams: true });
  const on = (k) => !only || only.includes(k);
  if (on('list'))   r.get('/', authorize(`${perm}:read`), ctrl.list);
  if (on('get'))    r.get('/:id', authorize(`${perm}:read`), ctrl.get);
  if (on('create')) r.post('/', authorize(`${perm}:write`), ctrl.create);
  if (on('update')) r.put('/:id', authorize(`${perm}:write`), ctrl.update);
  if (on('remove')) r.delete('/:id', authorize(`${perm}:write`), ctrl.remove);
  return r;
}

module.exports = { crudController, crudRouter, pick };
