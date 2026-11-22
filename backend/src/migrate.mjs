import { readFile } from 'node:fs/promises';
import { createPool } from './database.mjs';

const pool = createPool();
try {
  const sql = await readFile(new URL('../prisma/migrations/001_initial/migration.sql', import.meta.url), 'utf8');
  const homework = await readFile(new URL('../prisma/migrations/002_individual_homework/migration.sql', import.meta.url), 'utf8');
  await pool.query(sql + '\n' + homework);
  console.log('Class Desk sync schema is ready.');
} catch {
  console.error('Migration failed. Check the Neon URL, permissions and network.');
  process.exitCode = 1;
} finally {
  await pool.end();
}