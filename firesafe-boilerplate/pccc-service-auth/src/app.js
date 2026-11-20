const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const env = require('./config/env');
const db = require('./config/db');
const routes = require('./routes');
const notFound = require('./middlewares/notFound');
const errorHandler = require('./middlewares/errorHandler');

const app = express();
app.use(helmet());
app.use(cors({ origin: env.corsOrigin }));
app.use(express.json({ limit: '2mb' }));
if (env.nodeEnv !== 'test') app.use(morgan('dev'));

// Health check cho Docker / gateway
app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', service: process.env.SERVICE_NAME || 'service' });
  } catch (e) {
    res.status(503).json({ status: 'db_down' });
  }
});

app.use('/api/v1', routes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
