import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Thin wrapper over Supabase Storage.
///
/// Files are stored under a per-user folder (the user's auth UUID), which lines
/// up with typical Storage RLS policies like:
///   (storage.foldername(name))[1] = auth.uid()::text
class StorageService {
  SupabaseClient get _client => Supabase.instance.client;
  String get _bucket => AppConfig.storageBucket;

  String _userPath(String fileName) {
    final uid = _client.auth.currentUser?.id ?? 'anonymous';
    return '$uid/$fileName';
  }

  /// Upload raw bytes (e.g. an avatar) and return the storage path.
  Future<String> uploadBytes(String fileName, Uint8List bytes) async {
    final path = _userPath(fileName);
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Get a temporary signed URL to download a previously uploaded file.
  Future<String> signedUrl(String path, {int expiresInSeconds = 3600}) {
    return _client.storage.from(_bucket).createSignedUrl(path, expiresInSeconds);
  }

  /// List the current user's files in the bucket.
  Future<List<FileObject>> listMyFiles() {
    final uid = _client.auth.currentUser?.id ?? 'anonymous';
    return _client.storage.from(_bucket).list(path: uid);
  }
}
