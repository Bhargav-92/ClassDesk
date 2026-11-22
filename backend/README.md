# Class Desk sync backend

This Express API is a single-tenant deployment. Use a Neon database or branch
dedicated to one Class Desk roster. Devices connected to the same backend and
token share that roster. Node.js 22 or later and pnpm are required.

## Configure and run

From the project directory in PowerShell:

```powershell
Set-Location backend
pnpm install --frozen-lockfile
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
```

Add the Neon connection string to `DATABASE_URL`. Keep the TLS options that Neon
includes in the URL. Generate a separate random value for `SYNC_TOKEN` using the
following command and paste that value into `.env`.

```powershell
node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
```

For Chrome on port 8080, use `CORS_ORIGINS=http://localhost:8080`. Add other
explicit browser origins as a comma-separated list. Run:

```powershell
pnpm run migrate
pnpm start
```

In a second terminal, run `flutter run -d chrome --web-port 8080` from the
Flutter project directory. In Class Desk, open **Settings → Sync**, set
**Backend URL** to `http://localhost:3000`, and paste **Sync token**. Save the
settings, then tap **Sync now**.

For a phone or deployment, serve the Node app through an HTTPS host and use its
public HTTPS URL in the app. Set the same backend environment variables in the
hosting provider. The Flutter app stores the backend URL and sync token in
platform secure storage. Browser secure storage requires HTTPS or localhost.

## Schema and tests

`pnpm run migrate` applies the SQL migration in `prisma/migrations`. The
Prisma schema describes these tables. The API uses parameterized
node-postgres queries and an explicit transaction for each upload batch.

`pnpm test` runs against an in-process PostgreSQL database and needs no Neon
credentials. The Flutter tests use SQLite and a simulated network transport.

Rows use UUIDs and Unix microsecond timestamps. The newest update wins, with
the server's existing row winning timestamp ties. Each server change gets a
revision in a transaction. The app uses the revision as its pull cursor and
stores the last successful sync time separately. Deletes travel as
tombstones, and retries reuse the same UUID. A conflicting active monthly fee
for the same student and month is rejected with local data preserved.