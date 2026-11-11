# Teacher portal frontend

Run `pnpm dev` and open http://localhost:3000.

The directory reads `GET /api/students` from `VITE_API_URL` (default `http://localhost:4000`). Expected response: `{ success: true, message: string, data: Student[] }`. Fees arrive in paise and display in INR.

## Structure

The feature follows the realestate-webapp API / query-key / hook convention:

```text
src/
  lib/
    api.ts                  # shared Axios client and normalized errors
    query-client.ts         # SSR-safe QueryClient factory
    query-factory.ts        # shared hierarchical query-key factory
    format.ts               # date and currency display
  types/api.ts              # backend response envelope
  features/students/
    api/get-students.ts      # request only; no React or query cache
    queries/keys.ts          # studentKeys from createQueryKeys
    hooks/useStudents.ts    # composes API request and query key
    types/students.ts       # Student and StudentsResponse
    schemas/students-schema.ts # runtime response validation
    columns/students-columns.tsx
    components/student-directory.tsx
    index.ts                # public feature exports
```

The route imports the feature's public entry. QueryClient is created per root instance so server requests do not share caches. Requests forward TanStack Query's cancellation signal.

The backend currently exposes only an unpaginated student list. Search, sorting, column filters, visibility and pagination therefore remain in TanStack Table. Add server filters to the API function, list key and hook together when the backend supports them. CSV exports all filtered records across pages. No student write endpoints or auth-refresh endpoints are assumed.

Validate with `pnpm exec tsc --noEmit` and `pnpm build`.
