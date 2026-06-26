import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/pomodoro_session.dart';

/// Talks to the Laravel pomodoro-session API, attaching the Supabase JWT.
class PomodoroService {
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

  Future<PomodoroSession> log({String? task, required int durationMinutes}) async {
    final res = await http.post(
      _uri('/sessions'),
      headers: _headers(),
      body: jsonEncode({'task': task, 'duration_minutes': durationMinutes}),
    );
    if (res.statusCode == 201) {
      return PomodoroSession.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to log session (${res.statusCode}).');
  }

  Future<void> delete(int id) async {
    final res = await http.delete(_uri('/sessions/$id'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete session (${res.statusCode}).');
    }
  }
}
