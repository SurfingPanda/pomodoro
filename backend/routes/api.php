<?php

use App\Http\Controllers\PomodoroSessionController;
use App\Http\Controllers\TaskController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Auth (login/register) is handled by Supabase directly from the Flutter app.
// These routes are the Laravel data API; they require a valid Supabase JWT,
// verified by the "supabase" middleware.
Route::middleware('supabase')->group(function () {
    // Returns the authenticated Supabase user (decoded from the JWT).
    Route::get('/user', function (Request $request) {
        return response()->json($request->attributes->get('supabase_user'));
    });

    // Pomodoro sessions — all scoped to the authenticated user.
    Route::get('/sessions', [PomodoroSessionController::class, 'index']);
    Route::post('/sessions', [PomodoroSessionController::class, 'store']);
    Route::delete('/sessions/{id}', [PomodoroSessionController::class, 'destroy']);
    Route::get('/stats', [PomodoroSessionController::class, 'stats']);

    // Tasks — scoped to the authenticated user.
    Route::get('/tasks', [TaskController::class, 'index']);
    Route::post('/tasks', [TaskController::class, 'store']);
    Route::patch('/tasks/{id}', [TaskController::class, 'update']);
    Route::delete('/tasks/{id}', [TaskController::class, 'destroy']);
});
