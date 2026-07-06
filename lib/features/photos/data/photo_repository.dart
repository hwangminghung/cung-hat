import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Tiny injectable seam over the Supabase Storage builder chain.
///
/// `client.storage.from('profile-photos').uploadBinary(...)` / `.remove(...)` is
/// a multi-hop builder that is awkward to mock with mocktail (each `.from()`
/// returns a fresh `StorageFileApi`). Extracting the two calls we make behind
/// this interface keeps [PhotoRepository] fully testable, while the RPC and
/// Edge Function calls are still exercised against the real `SupabaseClient`.
abstract class PhotoStorage {
  Future<void> upload(String path, Uint8List bytes);
  Future<void> remove(List<String> paths);
}

class _SupabasePhotoStorage implements PhotoStorage {
  _SupabasePhotoStorage(this._client);
  final SupabaseClient _client;

  static const _bucket = 'profile-photos';

  @override
  Future<void> upload(String path, Uint8List bytes) async {
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
  }

  @override
  Future<void> remove(List<String> paths) async {
    await _client.storage.from(_bucket).remove(paths);
  }
}

class PhotoRepository {
  PhotoRepository(this._client, {PhotoStorage? storage})
      : _storage = storage ?? _SupabasePhotoStorage(_client);

  final SupabaseClient _client;
  final PhotoStorage _storage;

  /// Uploads [bytes] to the caller's folder at `'{uid}/{slot}_{millis}.jpg'`,
  /// then persists the new full path list (existing [current] + this new path)
  /// via `set_my_photo_paths`. Returns the resulting list.
  ///
  /// The repo needs the current list to append; the caller passes it as
  /// [current] (the UI derives it from `myPhotoPathsProvider`). This keeps the
  /// repo stateless and the method trivially testable.
  Future<List<String>> uploadPhoto(
    Uint8List bytes, {
    required int slot,
    List<String> current = const [],
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${slot}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _storage.upload(path, bytes);
    final next = [...current, path];
    await _client.rpc('set_my_photo_paths', params: {'p_paths': next});
    return next;
  }

  /// Removes [path] from storage, then persists [current] minus that path.
  /// Returns the resulting list.
  Future<List<String>> removePhoto(
    String path, {
    required List<String> current,
  }) async {
    await _storage.remove([path]);
    final next = current.where((p) => p != path).toList();
    await _client.rpc('set_my_photo_paths', params: {'p_paths': next});
    return next;
  }

  /// Signed URLs for [userId]'s photos. Returns an empty list for every failure
  /// mode — no photos, soft-deleted, or a blocked pair (the `sign-photo` edge
  /// function replies HTTP 403, which `invoke` surfaces as a thrown
  /// [FunctionException]) — so callers degrade to the monogram fallback instead
  /// of erroring the card/deck. Photos are cosmetic; the broad catch is
  /// intentional so transport/5xx errors also fall back rather than surface.
  Future<List<String>> signedUrlsOf(String userId) async {
    try {
      final res = await _client.functions.invoke('sign-photo', body: {'target_id': userId});
      final urls = res.data?['urls'] as List?;
      if (urls == null) return const [];

      // The edge `sign-photo` builds URLs from its runtime's SUPABASE_URL. On
      // local Supabase that is the internal Docker gateway (`http://kong:8000`),
      // which no emulator/device/browser can resolve. The signed token signs the
      // object PATH + expiry — NOT the host — so it stays valid on any origin of
      // the same project's storage. We therefore rebase each URL onto the app's
      // OWN configured Supabase origin, which the client always knows correctly
      // per environment. In production the origins already match, so this is a
      // no-op; on local/emulator it makes photos reachable.
      final base = Uri.parse(_client.storage.url);
      return urls.map((e) => rebaseOrigin(e as String, base)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Returns [url] with its origin (scheme + host + port) fully replaced by
  /// [base]'s, preserving only the path and query (e.g. the `?token=...`). The
  /// incoming URL's own port is dropped, not grafted onto [base]'s host — a
  /// default-port [base] yields no `:port` artifact (`Uri.replace(port: 443)` on
  /// an https URI omits `:443`). Unparseable input is returned unchanged so one
  /// bad URL never breaks the batch. Pure and directly unit-tested; see
  /// [signedUrlsOf] for why the rewrite is needed. Khong con @visibleForTesting:
  /// LikeTeaser.rebase (likes-teaser edge tra URL cung dang kong:8000) dung
  /// chung helper nay tu production code.
  static String rebaseOrigin(String url, Uri base) {
    final Uri u;
    try {
      u = Uri.parse(url);
    } catch (_) {
      return url;
    }
    return u
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.port,
        )
        .toString();
  }
}
