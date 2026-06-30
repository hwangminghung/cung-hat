import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatMediaUploader {
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  });

  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  });
}

class SupabaseChatMediaUploader implements ChatMediaUploader {
  SupabaseChatMediaUploader(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  }) {
    return _client.storage
        .from(bucketId)
        .upload(
          objectPath,
          file,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
  }

  @override
  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  }) {
    return _client.storage
        .from(bucketId)
        .createSignedUrl(objectPath, expiresInSeconds);
  }
}
