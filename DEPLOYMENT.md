# Launch ClassDesk demo: Vercel + Render

This is a public demo using sample data and one demo login. No deployment was performed by the assistant.

## 1. Push the repository

Commit the reviewed changes and push them to `Bhargav-92/ClassDesk`.

## 2. Create hosted PostgreSQL

In Render, create a PostgreSQL database in the same region as the API. Keep its internal connection URL private. Your existing localhost database is not accessible from Render. Run migrations on the new database; do not copy real student data into the demo.

Render's free PostgreSQL database expires after 30 days. Its free web service sleeps when idle and can take about a minute to wake.

## 3. Create the backend web service on Render

Connect the ClassDesk GitHub repository and use:

| Setting | Value |
| --- | --- |
| Root directory | `backend` |
| Runtime | Node |
| Build command | `pnpm install --frozen-lockfile --prod=false && pnpm build` |
| Start command | `pnpm db:migrate && pnpm start` |
| Health check | `/api/health` |
| Instance | Free, for the demo |

Set environment variables in Render:

- `NODE_VERSION`: `24`
- `NODE_ENV`: `production`
- `DATABASE_URL`: your hosted PostgreSQL internal connection URL
- `FRONTEND_URL`: your final Vercel frontend origin, e.g. `https://your-project.vercel.app` (no trailing slash)
- `DEMO_EMAIL`: your chosen demo account email
- `DEMO_PASSWORD`: a new private demo password; set it on the backend only

Render provides `PORT`; do not hardcode a localhost port there. The start command applies committed migrations before starting the API. It does not seed records automatically.

The demo account uses backend-verified credentials and random bearer session tokens. Sessions expire after 12 hours, end on sign-out, and are cleared when the API restarts. Keep this single-instance demo on sample data. There is no registration/password-reset flow.

## 4. Deploy the frontend on Vercel

Import the same repository:

| Setting | Value |
| --- | --- |
| Root directory | `frontend` |
| Framework | TanStack Start |
| Build command | `pnpm build` |
| Node version | 24.x |
| Output directory | Leave at the framework default |

Set `VITE_API_URL` to the Render API origin, e.g. `https://your-api.onrender.com` (without `/api`). Do not put the demo password or database URL in frontend variables.

After Vercel assigns its URL, update Render's `FRONTEND_URL` to that exact origin. Changing `VITE_API_URL` requires a frontend rebuild/redeploy.

## 5. Verify the live demo

1. Open the Vercel URL and sign in with the demo account.
2. Check Students, Fees and Attendance.
3. Add a sample student and confirm the backend success toast.
4. Sign out and confirm protected pages return to sign-in.
5. A direct unauthenticated request to `/api/students` should return 401.

You can add demo records through the student form. Existing seed commands are available for an initial sample dataset; run them deliberately against the hosted database only, because the student seed inserts new rows on every run.

Official references:
- https://vercel.com/docs/frameworks/full-stack/tanstack-start
- https://render.com/docs/deploy-node-express-app
- https://render.com/docs/free
