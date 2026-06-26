# Pomodoro — Login

A login/auth foundation for a Pomodoro app.

```
Flutter app (mobile/)
  ├─ Supabase Auth      → login / register (returns a JWT)
  ├─ Supabase Storage   → file uploads
  └─ Laravel API (backend/)  ← sends the Supabase JWT as a Bearer token
          │  verifies JWT (HS256 + project JWT secret)
          ▼
     Supabase PostgreSQL
```

- **Supabase** owns authentication and file storage. The Flutter app talks to it
  directly via the `supabase_flutter` SDK.
- **Flutter** (`mobile/`) — register / login / logout UI against Supabase Auth;
  session is persisted by the SDK; the JWT is forwarded to Laravel.
- **Laravel** (`backend/`) — the data API for Pomodoro app data. It does **not**
  do login; it verifies the Supabase JWT on each request via the `supabase`
  middleware and reads the same Supabase Postgres.

## API endpoints (Laravel)

All require a valid Supabase JWT as a Bearer token (verified by the `supabase`
middleware). Session routes are scoped to the authenticated user.

| Method | Path                  | Purpose                                  |
|--------|-----------------------|------------------------------------------|
| GET    | `/api/user`           | The user decoded from the JWT            |
| GET    | `/api/sessions`       | List the user's pomodoro sessions        |
| POST   | `/api/sessions`       | Log a session (`task?`, `duration_minutes`) |
| DELETE | `/api/sessions/{id}`  | Delete one of the user's sessions        |
| GET    | `/api/stats`          | Totals: sessions/minutes (all-time + today) |

Sessions are stored in `pomodoro_sessions`, keyed by the Supabase user UUID
(`$request->attributes->get('supabase_user')['id']`). The Flutter app consumes
these via `mobile/lib/services/pomodoro_service.dart` on the home screen.

---

## 1. Set up Supabase

1. Create a project at https://supabase.com.
2. **Project Settings → API**: copy the **Project URL**, the **publishable**
   (a.k.a. anon public) key, and the **JWT secret**.
3. **Project Settings → Database → Connection string**: copy the **Session
   pooler** values (host, port `5432`, user, database `postgres`) + your DB password.
4. (Optional, for uploads) **Storage**: create a bucket named `uploads`.
5. (For quick testing) **Authentication → Providers → Email**: you may turn off
   "Confirm email" so sign-up logs in immediately.

## 2. Configure & run the Laravel backend

Edit `backend/.env`:

```dotenv
# Database (Supabase Postgres)
DB_CONNECTION=pgsql
DB_HOST=aws-0-REGION.pooler.supabase.com
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres.YOUR_PROJECT_REF
DB_PASSWORD=YOUR_SUPABASE_DB_PASSWORD
DB_SSLMODE=require

# Supabase Auth (JWT verification)
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_JWT_SECRET=YOUR_SUPABASE_JWT_SECRET
```

Then, from `backend/`:

```bash
php artisan serve        # serves the API at http://127.0.0.1:8000
```

> Auth tables live in Supabase (`auth.users`), so no `php artisan migrate` is
> needed for login. Run migrations only when you add your own app tables.

## 3. Run the Flutter app

Set credentials in `mobile/lib/config.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
static const String supabaseKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';
static const String apiBaseUrl = 'http://10.0.2.2:8000/api'; // see notes below
```

`apiBaseUrl` by target:
- Android emulator → `http://10.0.2.2:8000/api` (default)
- iOS simulator / desktop / web → `http://127.0.0.1:8000/api`
- Physical device → `http://YOUR-COMPUTER-LAN-IP:8000/api`

Then, from `mobile/`:

```bash
flutter run
```

The home screen has a **Test Laravel API** button that calls `/api/user` with
the Supabase JWT — a green result confirms the full Flutter → Supabase → Laravel
chain works.

> **Windows desktop builds** require Developer Mode enabled (for plugin
> symlinks): `start ms-settings:developers`. Android/iOS/web are unaffected.

## Project layout

```
backend/
  app/Http/Middleware/VerifySupabaseToken.php   # verifies the Supabase JWT
  routes/api.php                                # protected data API
  config/services.php                          # supabase.url / supabase.jwt_secret
mobile/
  lib/config.dart                              # all credentials + API URL
  lib/services/auth_service.dart               # Supabase Auth wrapper
  lib/services/api_service.dart                # calls Laravel with the JWT
  lib/services/storage_service.dart            # Supabase Storage helper
  lib/screens/{login,register,home}_screen.dart
  lib/main.dart                                # Supabase init + AuthGate
```
