import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/pomodoro_session.dart';

/// Result of attempting to record a session.
enum LogOutcome {
  /// Sent to the server successfully.
  synced,

  /// Couldn't reach the server; saved to the local queue to sync later.
  queued,
}

/// Talks to the Laravel pomodoro-session API, attaching the Supabase JWT.
///
/// Logging is offline-tolerant: [logOrQueue] persists the session locally if the
/// API can't be reached (e.g. a Render free-tier cold start drops the request),
/// and [flushPending] retries the queue on app start / dashboard refresh, so a
/// completed session is never silently lost.
class PomodoroService {
  static const _pendingKey = 'pending_sessions';

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PomodoroSession>> list() async {
    final res = await http.get(_uri('/sessions'), headers: _headers());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => PomodoroSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load sessions (${res.statusCode}).');
  }

  Future<PomodoroStats> stats() async {
    final res = await http.get(_uri('/stats'), headers: _headers());
    if (res.statusCode == 200) {
      return PomodoroStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load stats (${res.statusCode}).');
  }

  /// POST a session to the API. Throws on any non-201 response or network error.
  Future<PomodoroSession> log({
    String? task,
    required int durationMinutes,
    DateTime? completedAt,
  }) async {
    final res = await http.post(
      _uri('/sessions'),
      headers: _headers(),
      body: jsonEncode({
        'task': task,
        'duration_minutes': durationMinutes,
        if (completedAt != null) 'completed_at': completedAt.toUtc().toIso8601String(),
      }),
    );
    if (res.statusCode == 201) {
      return PomodoroSession.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to log session (${res.statusCode}).');
  }

  /// Record a finished session, falling back to the local queue when offline.
  /// The completion time is captured now so a later sync keeps the real time.
  Future<LogOutcome> logOrQueue({String? task, required int durationMinutes}) async {
    final completedAt = DateTime.now();
    try {
      await log(task: task, durationMinutes: durationMinutes, completedAt: completedAt);
      // Connectivity is good — opportunistically drain anything queued earlier.
      await flushPending();
      return LogOutcome.synced;
    } catch (_) {
      await _enqueue({
        'task': task,
        'duration_minutes': durationMinutes,
        'completed_at': completedAt.toUtc().toIso8601String(),
      });
      return LogOutcome.queued;
    }
  }

  Future<void> delete(int id) async {
    final res = await http.delete(_uri('/sessions/$id'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete session (${res.statusCode}).');
    }
  }

  // --- Offline queue -------------------------------------------------------

  Future<List<Map<String, dynamic>>> _readQueue(SharedPreferences prefs) async {
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _enqueue(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _readQueue(prefs);
    queue.add(entry);
    await prefs.setString(_pendingKey, jsonEncode(queue));
  }

  /// Number of sessions waiting to sync.
  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (await _readQueue(prefs)).length;
  }

  /// Try to POST every queued session (oldest first). Stops at the first
  /// failure (still offline) and keeps the remainder. Returns how many synced.
  Future<int> flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _readQueue(prefs);
    if (queue.isEmpty) return 0;

    var synced = 0;
    final remaining = List<Map<String, dynamic>>.from(queue);
    for (final entry in queue) {
      try {
        await log(
          task: entry['task'] as String?,
          durationMinutes: entry['duration_minutes'] as int,
          completedAt: DateTime.tryParse(entry['completed_at'] as String? ?? ''),
        );
        remaining.removeAt(0);
        synced++;
      } catch (_) {
        break; // still offline — keep the rest for next time
      }
    }
    if (synced > 0) {
      await prefs.setString(_pendingKey, jsonEncode(remaining));
    }
    return synced;
  }
}
