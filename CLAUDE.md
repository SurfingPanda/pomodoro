# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Pomodoro app split into two independently-run projects:

- `backend/` — Laravel 12 (PHP 8.2) JSON data API.
- `mobile/` — Flutter app (Dart SDK ^3.12.2), the only client.

**Supabase is the system of record for auth and storage.** The Flutter app talks
to Supabase Auth directly (via `supabase_flutter`) for login/register and gets a
JWT. That JWT is sent as a Bearer token to the Laravel API, which does **not** do
login — it verifies the token and serves pomodoro/task data out of the same
Supabase Postgres database.

```
Flutter (mobile/) ──login/register──▶ Supabase Auth ──▶ JWT
        │                                                  │
        └── Bearer JWT ──▶ Laravel API (backend/) ──┐      │
                              verifies JWT via       │      │
                              Supabase /auth/v1/user ▼      ▼
                                          Supabase Postgres (shared)
```

> **README drift:** `README.md` describes JWT verification as "HS256 + JWT
> secret." That is outdated. The real middleware
> (`backend/app/Http/Middleware/VerifySupabaseToken.php`) verifies tokens by
> calling Supabase's `GET /auth/v1/user` with the project URL + **anon key**
> (config keys `services.supabase.url` / `services.supabase.anon_key`, env
> `SUPABASE_URL` / `SUPABASE_ANON_KEY`). There is no `SUPABASE_JWT_SECRET`.

## Commands

### Backend (run from `backend/`)
```bash
php artisan serve                       # API at http://127.0.0.1:8000
composer dev                            # serve + queue + logs (pail) + vite, concurrently
composer test                           # clears config, then runs the suite
php artisan test                        # PHPUnit (tests/Feature, tests/Unit)
php artisan test --filter=SomeTest      # run a single test class/method
./vendor/bin/pint                       # format (Laravel Pint)
php artisan migrate                     # only for app tables; auth lives in Supabase
```

### Mobile (run from `mobile/`)
```bash
flutter run                             # default target = Android emulator
flutter run -d chrome                   # web
flutter test                            # all widget/unit tests
flutter test test/widget_test.dart      # a single test file
flutter analyze                         # lints (flutter_lints, see analysis_options.yaml)
dart run flutter_launcher_icons         # regenerate app icons from assets/icon/
```

> **Windows desktop builds** need Developer Mode (plugin symlinks):
> `start ms-settings:developers`. Android/iOS/web are unaffected.

## Configuration

- **Mobile** credentials are hard-coded constants in `mobile/lib/config.dart`
  (`supabaseUrl`, `supabaseKey`, `storageBucket`, `apiBaseUrl`). There is no
  `.env` for Flutter. `apiBaseUrl` must match your run target — Android emulator
  uses `http://10.0.2.2:8000/api`; iOS sim / desktop / web use `127.0.0.1`; a
  physical device needs your machine's LAN IP.
- **Backend** config is `backend/.env`. DB is Supabase Postgres
  (`DB_CONNECTION=pgsql`, session pooler host, `DB_SSLMODE=require`). A
  `database/database.sqlite` file exists from Laravel scaffolding but is not the
  app database.

## Architecture notes

**Auth is decentralized.** Laravel never sees passwords. Every protected route
is wrapped in the `supabase` middleware alias (registered in
`backend/bootstrap/app.php`, all routes grouped in `backend/routes/api.php`).
The middleware resolves the token to a user and attaches it as the
`supabase_user` request attribute; successful lookups are cached 60s by token
hash to avoid hitting Supabase on every request.

**User scoping is manual and load-bearing.** There is no Eloquent auth guard.
Controllers read the Supabase user UUID via
`$request->attributes->get('supabase_user')['id']` (see the `userId()` helper in
both `PomodoroSessionController` and `TaskController`) and **must** filter every
query by `user_id`. The `pomodoro_sessions` / `tasks` tables key off this UUID,
not a local users-table FK. When adding endpoints, always scope by `userId`.

**Stats are aggregated in PHP, not SQL** (`PomodoroSessionController::stats`).
It fetches all of a user's session rows once and computes totals, today/week
buckets, a 7-day daily chart series, and the current streak in a single loop —
deliberately one round-trip, since the pooled remote DB makes many small queries
expensive. The shape it returns drives `stats_tab.dart` and `weekly_chart.dart`.

**Mobile structure.** `lib/main.dart` initializes Supabase and renders
`AuthGate`, a `StreamBuilder` on `onAuthStateChange` that swaps between
`LoginScreen` and `MainShell`. `MainShell` is a 5-tab bottom nav (dashboard,
sessions, tasks, stats, profile); it wraps each tab in a `KeyedSubtree` keyed by
tab index so switching tabs forces a rebuild and a data refetch (there is no
shared state store — each tab fetches on build). Service classes in
`lib/services/` are the only HTTP/SDK boundary: `auth_service` wraps Supabase
Auth, `storage_service` wraps Supabase Storage, and `pomodoro_service` /
`task_service` call the Laravel API, attaching the current JWT from
`Supabase.instance.client.auth.currentSession` on each request.
