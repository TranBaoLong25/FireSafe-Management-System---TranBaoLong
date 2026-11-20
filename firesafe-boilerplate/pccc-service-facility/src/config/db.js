const { Pool } = require('pg');
const env = require('./env');

const pool = new Pool({ connectionString: env.databaseUrl, max: 10 });

pool.on('error', (err) => console.error('[db] Lỗi kết nối bất ngờ:', err.message));

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  // Chạy nhiều câu lệnh trong 1 transaction: await db.tx(async (c) => { await c.query(...) })
  async tx(fn) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  },
};
