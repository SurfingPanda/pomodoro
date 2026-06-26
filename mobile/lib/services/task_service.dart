import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/task.dart';

/// Talks to the Laravel tasks API, attaching the Supabase JWT.
class TaskService {
  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Task>> list() async {
    final res = await http.get(_uri('/tasks'), headers: _headers());
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List<dynamic>)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load tasks (${res.statusCode}).');
  }

  Future<Task> create(String title) async {
    final res = await http.post(
      _uri('/tasks'),
      headers: _headers(),
      body: jsonEncode({'title': title}),
    );
    if (res.statusCode == 201) {
      return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create task (${res.statusCode}).');
  }

  Future<Task> setDone(int id, bool isDone) async {
    final res = await http.patch(
      _uri('/tasks/$id'),
      headers: _headers(),
      body: jsonEncode({'is_done': isDone}),
    );
    if (res.statusCode == 200) {
      return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update task (${res.statusCode}).');
  }

  Future<void> delete(int id) async {
    final res = await http.delete(_uri('/tasks/$id'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete task (${res.statusCode}).');
    }
  }
}
