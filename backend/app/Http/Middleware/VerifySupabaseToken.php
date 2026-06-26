<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

/**
 * Verifies the Supabase-issued JWT sent by the Flutter client by asking
 * Supabase Auth to resolve it (GET /auth/v1/user). This needs only the project
 * URL + anon key and works regardless of how the token is signed (legacy HS256
 * secret or the newer asymmetric signing keys). Successful lookups are cached
 * briefly so we don't call Supabase on every request.
 *
 * On success the resolved user is attached as the "supabase_user" attribute.
 */
class VerifySupabaseToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (! $token) {
            return response()->json(['message' => 'Missing bearer token.'], 401);
        }

        $url = config('services.supabase.url');
        $anonKey = config('services.supabase.anon_key');

        if (! $url || ! $anonKey) {
            return response()->json(['message' => 'Supabase is not configured.'], 500);
        }

        $user = Cache::remember(
            'supabase_user:'.sha1($token),
            now()->addSeconds(60),
            function () use ($url, $anonKey, $token) {
                $response = Http::withHeaders([
                    'apikey' => $anonKey,
                    'Authorization' => 'Bearer '.$token,
                ])->get(rtrim($url, '/').'/auth/v1/user');

                if (! $response->successful()) {
                    return null;
                }

                $data = $response->json();

                return [
                    'id' => $data['id'] ?? null,        // Supabase auth user UUID
                    'email' => $data['email'] ?? null,
                    'role' => $data['role'] ?? null,
                ];
            }
        );

        if (! $user) {
            Cache::forget('supabase_user:'.sha1($token));

            return response()->json(['message' => 'Invalid or expired token.'], 401);
        }

        $request->attributes->set('supabase_user', $user);

        return $next($request);
    }
}
