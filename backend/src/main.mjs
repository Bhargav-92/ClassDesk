import { createPool } from './database.mjs';
import { createApp } from './server.mjs';

const pool = createPool();
pool.on('error', () => console.error('An idle database connection failed.'));
const app = createApp({
  pool,
  token: process.env.SYNC_TOKEN,
  origins: (process.env.CORS_ORIGINS ?? '').split(',').map(value => value.trim()).filter(Boolean),
});
const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => console.log(`Class Desk sync API listening on port ${port}`));