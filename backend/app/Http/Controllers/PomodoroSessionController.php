<?php

namespace App\Http\Controllers;

use App\Models\PomodoroSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PomodoroSessionController extends Controller
{
    /**
     * The authenticated Supabase user's UUID (set by VerifySupabaseToken).
     */
    private function userId(Request $request): string
    {
        return $request->attributes->get('supabase_user')['id'];
    }

    /**
     * List the current user's recent pomodoro sessions.
     */
    public function index(Request $request): JsonResponse
    {
        $sessions = PomodoroSession::where('user_id', $this->userId($request))
            ->orderByDesc('completed_at')
            ->limit(100)
            ->get();

        return response()->json($sessions);
    }

    /**
     * Record a completed pomodoro session for the current user.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'task' => ['nullable', 'string', 'max:255'],
            'duration_minutes' => ['required', 'integer', 'min:1', 'max:240'],
            'completed_at' => ['nullable', 'date'],
        ]);

        $session = PomodoroSession::create([
            'user_id' => $this->userId($request),
            'task' => $data['task'] ?? null,
            'duration_minutes' => $data['duration_minutes'],
            'completed_at' => $data['completed_at'] ?? now(),
        ]);

        return response()->json($session, 201);
    }

    /**
     * Delete one of the current user's sessions.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $deleted = PomodoroSession::where('user_id', $this->userId($request))
            ->where('id', $id)
            ->delete();

        if (! $deleted) {
            return response()->json(['message' => 'Session not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.']);
    }

    /**
     * Aggregate focus stats for the current user's dashboard.
     */
    public function stats(Request $request): JsonResponse
    {
        $userId = $this->userId($request);

        // Single query — everything below is aggregated in PHP. This avoids the
        // many sequential round-trips a pooled remote DB would otherwise incur.
        $rows = PomodoroSession::where('user_id', $userId)
            ->get(['duration_minutes', 'completed_at']);

        $weekStart = today()->startOfWeek();

        $totalMinutes = 0;
        $todaySessions = 0;
        $todayMinutes = 0;
        $weekSessions = 0;
        $weekMinutes = 0;
        $minutesByDate = [];
        $activeDates = [];

        foreach ($rows as $r) {
            $totalMinutes += $r->duration_minutes;
            $date = $r->completed_at->toDateString();
            $minutesByDate[$date] = ($minutesByDate[$date] ?? 0) + $r->duration_minutes;
            $activeDates[$date] = true;

            if ($r->completed_at->isToday()) {
                $todaySessions++;
                $todayMinutes += $r->duration_minutes;
            }
            if ($r->completed_at >= $weekStart) {
                $weekSessions++;
                $weekMinutes += $r->duration_minutes;
            }
        }

        // Last 7 days (oldest -> newest) for the chart.
        $daily = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = today()->subDays($i);
            $key = $day->toDateString();
            $daily[] = [
                'date' => $key,
                'label' => $day->isoFormat('dd'), // Mo, Tu, We...
                'minutes' => (int) ($minutesByDate[$key] ?? 0),
            ];
        }

        // Current streak: consecutive days (ending today/yesterday) with focus.
        $streak = 0;
        $cursor = today();
        if (! isset($activeDates[$cursor->toDateString()])) {
            $cursor = $cursor->subDay(); // a streak can still be "alive" from yesterday
        }
        while (isset($activeDates[$cursor->toDateString()])) {
            $streak++;
            $cursor = $cursor->subDay();
        }

        return response()->json([
            'total_sessions' => $rows->count(),
            'total_minutes' => $totalMinutes,
            'today_sessions' => $todaySessions,
            'today_minutes' => $todayMinutes,
            'week_minutes' => $weekMinutes,
            'week_sessions' => $weekSessions,
            'streak_days' => $streak,
            'daily' => $daily,
        ]);
    }
}
