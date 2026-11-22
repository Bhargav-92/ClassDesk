import pg from 'pg';

export function createPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) throw new Error('Set DATABASE_URL in backend/.env.');
  return new pg.Pool({ connectionString, connectionTimeoutMillis: 10000 });
}