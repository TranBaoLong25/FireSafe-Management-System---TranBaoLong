require('dotenv').config();

const required = ['DATABASE_URL', 'JWT_SECRET'];
for (const k of required) {
  if (!process.env[k]) {
    console.error(`[env] Thiếu biến môi trường bắt buộc: ${k}`);
    process.exit(1);
  }
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,
  databaseUrl: process.env.DATABASE_URL,
  jwt: {
    secret: process.env.JWT_SECRET,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresDays: parseInt(process.env.JWT_REFRESH_EXPIRES_DAYS, 10) || 7,
  },
  corsOrigin: process.env.CORS_ORIGIN || '*',
};
