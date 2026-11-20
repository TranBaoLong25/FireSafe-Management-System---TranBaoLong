// Tạo tài khoản ADMIN đầu tiên:  ADMIN_USERNAME=admin ADMIN_PASSWORD='Admin@12345' npm run seed:admin
require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../src/config/db');

(async () => {
  const username = process.env.ADMIN_USERNAME || 'admin';
  const password = process.env.ADMIN_PASSWORD;
  if (!password || password.length < 8) { console.error('Cần ADMIN_PASSWORD (>= 8 ký tự)'); process.exit(1); }
  const hash = await bcrypt.hash(password, 10);
  await db.tx(async (c) => {
    const u = await c.query(
      `INSERT INTO users (username, password_hash, full_name) VALUES ($1,$2,'Quản trị hệ thống')
       ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash RETURNING user_id`, [username, hash]);
    await c.query(
      `INSERT INTO user_roles (user_id, role_id) SELECT $1, role_id FROM roles WHERE code = 'ADMIN'
       ON CONFLICT DO NOTHING`, [u.rows[0].user_id]);
  });
  console.log(`Đã tạo/cập nhật admin: ${username}`);
  await db.pool.end();
})().catch((e) => { console.error(e); process.exit(1); });
