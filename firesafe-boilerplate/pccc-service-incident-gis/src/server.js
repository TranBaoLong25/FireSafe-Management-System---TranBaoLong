const env = require('./config/env');
const db = require('./config/db');
const app = require('./app');

const server = app.listen(env.port, () =>
  console.log(`[${process.env.SERVICE_NAME || 'service'}] chạy tại cổng ${env.port} (${env.nodeEnv})`));

const shutdown = (sig) => {
  console.log(`[${sig}] đang tắt...`);
  server.close(async () => { await db.pool.end(); process.exit(0); });
  setTimeout(() => process.exit(1), 10000).unref();
};
['SIGINT', 'SIGTERM'].forEach((s) => process.on(s, () => shutdown(s)));
