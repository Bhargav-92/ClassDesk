import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { once } from 'node:events';
import { PGlite } from '@electric-sql/pglite';
import { createApp } from '../src/server.mjs';

test('authenticated push and pull are atomic, idempotent and ordered', async t => {
  const db = new PGlite();
  t.after(() => db.close());
  await db.exec(await readFile(new URL('../prisma/migrations/001_initial/migration.sql', import.meta.url), 'utf8'));
  await db.exec(await readFile(new URL('../prisma/migrations/002_individual_homework/migration.sql', import.meta.url), 'utf8'));
  const pool = { query: db.query.bind(db), connect: async () => ({
    query: db.query.bind(db), release() {},
  }) };
  const token = 'test-only-token-at-least-thirty-two-characters';
  const server = createApp({ pool, token, origins: ['http://localhost:8080'] }).listen(0, '127.0.0.1');
  t.after(() => new Promise(resolve => server.close(resolve)));
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}/v1/sync`;
  const auth = { authorization: `Bearer ${token}`, 'content-type': 'application/json', 'x-classdesk-sync-version': '2' };
  const student = {
    id: '6abc5a10-19d3-4b27-bf57-78df116c3ff4', created_at: 1, updated_at: 1,
    is_deleted: false, name: 'Test Student', batch: 'Test Batch',
    parent_name: 'Test Parent', parent_whatsapp: '+919000000000', monthly_fee_paise: 250000,
    joining_date: '2026-11-22', notes: null,
  };
  const row = (changes = {}) => ({ table: 'students', row: { ...student, ...changes } });
  const push = rows => fetch(`${url}/push`, {
    method: 'POST', headers: auth, body: JSON.stringify({ rows }),
  });
  const pull = async after => {
    const response = await fetch(`${url}/pull?after=${after}`, { headers: auth });
    assert.equal(response.status, 200);
    return response.json();
  };
  assert.equal((await fetch(`${url}/pull`)).status, 401);
  assert.equal((await fetch(`${url}/pull`, { headers: { ...auth, origin: 'https://untrusted.test' } })).status, 403);

  const invalid = { table: 'fee_records', row: {
    id: '25121eba-09d2-459e-99da-306f637a1216', created_at: 1, updated_at: 1,
    is_deleted: false, student_id: '6abc5a10-19d3-4b27-bf57-78df116c3ff5',
    month: '2026-11', amount_due_paise: 50000, due_date: '2026-11-30',
  } };
  assert.equal((await push([row(), invalid])).status, 409);
  assert.equal((await pull('0')).rows.length, 0);
  const created = await push([row()]);
  assert.equal(created.status, 200, await created.clone().text());
  assert.equal((await push([row()])).status, 200);
  let changes = await pull('0');
  assert.equal(changes.next, '1');
  assert.equal(changes.rows.length, 1);
  assert.equal((await push([row({ updated_at: 5, is_deleted: true })])).status, 200);
  const stale = await (await push([row({ updated_at: 4 })])).json();
  assert.equal(stale.rows[0].row.updated_at, 5);
  assert.equal(stale.rows[0].row.is_deleted, true);
  changes = await pull('1');
  assert.equal(changes.next, '2');
  assert.equal(changes.rows[0].row.is_deleted, true);
});