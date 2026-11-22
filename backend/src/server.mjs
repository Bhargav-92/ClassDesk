import { createHash, timingSafeEqual } from 'node:crypto';
import express from 'express';
import { tables } from './tables.mjs';

export const pageSize = 100;
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const cursorPattern = /^(0|[1-9][0-9]{0,18})$/;
const maxCursor = 9223372036854775807n;
const order = Object.keys(tables);
const dateFields = new Set(['joining_date', 'due_date', 'paid_on', 'promised_date']);
function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(value + 'T00:00:00Z');
  return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
}
const hash = value => createHash('sha256').update(value).digest();

class RequestError extends Error {}

function validateField(value, spec) {
  if (value === null || value === undefined) return spec.includes('?');
  switch (spec[0]) {
    case 's': return typeof value === 'string' && value.length <= 16000 && !value.includes('\0');
    case 'u': return typeof value === 'string' && uuid.test(value);
    case 'b': return typeof value === 'boolean';
    case 'n': return Number.isSafeInteger(value) && value >= 0;
    case 'i': return Number.isSafeInteger(value) && value >= 0 && value <= 2147483647;
    default: return false;
  }
}

function parseRows(body) {
  if (!Array.isArray(body?.rows) || body.rows.length === 0 || body.rows.length > pageSize) {
    throw new RequestError('Send between 1 and 100 rows.');
  }
  const seen = new Set();
  return body.rows.map(item => {
    if (!item || typeof item.table !== 'string' || !Object.hasOwn(tables, item.table)) {
      throw new RequestError('Unknown sync table.');
    }
    const fields = tables[item.table];
    const row = item.row;
    if (!row || typeof row !== 'object' || !validateField(row.id, 'u') ||
        !validateField(row.created_at, 'n') || !validateField(row.updated_at, 'n') ||
        row.updated_at < row.created_at || !validateField(row.is_deleted, 'b')) {
      throw new RequestError('Invalid row metadata.');
    }
    for (const [name, spec] of Object.entries(fields)) {
      if (!validateField(row[name], spec)) throw new RequestError(`Invalid field ${name}.`);
    }
    for (const name of Object.keys(fields)) {
      if (dateFields.has(name) && !validDate(row[name])) {
        throw new RequestError('Invalid calendar date.');
      }
    }
    if (item.table === 'fee_records' && !/^\d{4}-(0[1-9]|1[0-2])$/.test(row.month)) {
      throw new RequestError('Invalid fee month.');
    }
    if (item.table === 'payments' &&
        (row.mode === 'razorpay' || row.razorpay_payment_id != null)) {
      throw new RequestError('Online payments require server verification.');
    }
    const key = `${item.table}:${row.id}`;
    if (seen.has(key)) throw new RequestError('A batch cannot repeat a row.');
    seen.add(key);
    return { table: item.table, row };
  }).sort((a, b) => order.indexOf(a.table) - order.indexOf(b.table) ||
      Number(b.row.is_deleted) - Number(a.row.is_deleted));
}

async function push(pool, items) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // One writer lock makes commit order match the order of pull revisions.
    await client.query('SELECT id FROM sync_clock WHERE id = 1 FOR UPDATE');
    const canonical = [];
    for (const { table, row } of items) {
      const columns = ['id', 'created_at', 'updated_at', 'is_deleted', ...Object.keys(tables[table])];
      const parameters = columns.map((name, index) => '$' + (index + 1));
      const updates = columns.slice(2).map(name => `${name} = EXCLUDED.${name}`);
      const result = await client.query(
        `INSERT INTO ${table} AS current_row (${columns.join(', ')}) VALUES (${parameters.join(', ')})
         ON CONFLICT (id) DO UPDATE SET ${updates.join(', ')}
         WHERE current_row.updated_at < EXCLUDED.updated_at
         RETURNING to_jsonb(current_row) AS row`,
        columns.map(name => row[name] ?? null),
      );
      let winner = result.rows[0]?.row;
      if (winner) {
        const tick = await client.query('UPDATE sync_clock SET revision = revision + 1 WHERE id = 1 RETURNING revision');
        await client.query(
          'INSERT INTO sync_changes (revision, table_name, row_data) VALUES ($1, $2, $3)',
          [tick.rows[0].revision, table, winner],
        );
      } else {
        const current = await client.query(`SELECT to_jsonb(t) AS row FROM ${table} t WHERE id = $1`, [row.id]);
        winner = current.rows[0].row;
      }
      canonical.push({ table, row: winner });
    }
    await client.query('COMMIT');
    return canonical;
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    throw error;
  } finally {
    client.release();
  }
}

function cursor(value) {
  if (typeof value !== 'string' || !cursorPattern.test(value) || BigInt(value) > maxCursor) {
    throw new RequestError('Invalid sync cursor.');
  }
  return value;
}

export function createApp({ pool, token, origins = [] }) {
  if (!token || token.length < 32 || /\s/.test(token)) {
    throw new Error('Set SYNC_TOKEN to a random token of at least 32 characters.');
  }
  const expected = hash(token);
  const app = express();
  app.disable('x-powered-by');
  app.use('/v1/sync', (req, res, next) => {
    res.set('Cache-Control', 'no-store');
    const origin = req.get('origin');
    if (origin) {
      if (!origins.includes(origin)) return res.status(403).json({ error: 'Browser origin is not allowed.' });
      res.vary('Origin');
      res.set('Access-Control-Allow-Origin', origin);
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-ClassDesk-Sync-Version');
      res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    }
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    const authorization = req.get('authorization') ?? '';
    if (!authorization.startsWith('Bearer ') ||
        !timingSafeEqual(expected, hash(authorization.slice(7)))) {
      return res.status(401).json({ error: 'Check the sync token in Settings.' });
    }
    if (req.path !== '/check' && req.get('X-ClassDesk-Sync-Version') !== '2') {
      return res.status(426).json({ error: 'Update Class Desk before syncing individual homework.' });
    }
    next();
  });
  app.use('/v1/sync', express.json({ limit: '2mb' }));

  app.post('/v1/sync/push', async (req, res) => {
    res.json({ rows: await push(pool, parseRows(req.body)) });
  });

  app.get('/v1/sync/check', async (_req, res) => {
    const state = await pool.query('SELECT id, (SELECT student_id FROM homework LIMIT 1) FROM sync_clock WHERE id = 1');
    if (state.rows.length !== 1) return res.status(503).json({ error: 'Run the backend migration.' });
    res.json({ rows: [], protocol: 2 });
  });

  app.get('/v1/sync/pull', async (req, res) => {
    const after = cursor(req.query.after ?? '0');
    const state = await pool.query('SELECT revision::text AS revision FROM sync_clock WHERE id = 1');
    const current = state.rows[0].revision;
    const through = req.query.through === undefined ? current : cursor(req.query.through);
    if (BigInt(through) > BigInt(current) || BigInt(after) > BigInt(through)) {
      return res.status(409).json({ error: 'The server sync history changed. Check your backend database.' });
    }
    const changes = await pool.query(
      'SELECT revision::text AS revision, table_name AS table, row_data AS row FROM sync_changes ' +
      'WHERE revision > $1 AND revision <= $2 ORDER BY sync_changes.revision LIMIT $3',
      [after, through, pageSize + 1],
    );
    const rows = changes.rows.slice(0, pageSize);
    const more = changes.rows.length > pageSize;
    res.json({ rows, through, next: more ? rows.at(-1).revision : through, more });
  });

  app.use((error, _req, res, _next) => {
    if (error instanceof RequestError) return res.status(400).json({ error: error.message });
    if (error.type === 'entity.too.large') return res.status(413).json({ error: 'The sync batch is too large.' });
    if (error.type === 'entity.parse.failed') return res.status(400).json({ error: 'Invalid JSON.' });
    if (error.code === '23505') return res.status(409).json({ error: 'A monthly fee or payment conflicts with an existing record. Local edits are still safe.' });
    if (['23514', '23503', '23502', '22P02'].includes(error.code)) {
      return res.status(409).json({ error: 'The server rejected an invalid or unlinked record. Local edits are still safe.' });
    }
    console.error('Sync request failed', typeof error.code === 'string' ? error.code : '');
    return res.status(503).json({ error: 'The sync server is temporarily unavailable.' });
  });
  return app;
}