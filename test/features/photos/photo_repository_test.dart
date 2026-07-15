import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

class _MockGoTrue extends Mock implements GoTrueClient {}

class _MockStorage extends Mock implements SupabaseStorageClient {}

class _MockPhotoStorage extends Mock implements PhotoStorage {}

class _FakeUser extends Fake implements User {
  @override
  final String id;
  _FakeUser(this.id);
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  /// Stubs `client.storage.url` so the origin-rewrite step in [signedUrlsOf]
  /// has a base to rebase onto. Mirrors what the real client exposes:
  /// `http://<host>:<port>/storage/v1`.
  void stubStorageUrl(MockSupabaseClient client, String storageUrl) {
    final storage = _MockStorage();
    when(() => client.storage).thenReturn(storage);
    when(() => storage.url).thenReturn(storageUrl);
  }

  test('signedUrlsOf invokes sign-photo with target_id and returns urls', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    stubStorageUrl(client, 'http://10.0.2.2:54321/storage/v1');
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body'))).thenAnswer(
      (_) async => FunctionResponse(
        data: {
          'urls': [
            'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/a?token=x',
            'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/b?token=y',
          ],
        },
        status: 200,
      ),
    );

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    // Origins already match the client → unchanged (prod no-op case).
    expect(urls, [
      'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/a?token=x',
      'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/b?token=y',
    ]);
    verify(() => fns.invoke('sign-photo', body: {'target_id': 'user-9'})).called(1);
  });

  test('signedUrlsOf rewrites the kong internal host to the client origin', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    // App's own configured origin (emulator loopback to host Supabase).
    stubStorageUrl(client, 'http://10.0.2.2:54321/storage/v1');
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body'))).thenAnswer(
      (_) async => FunctionResponse(
        data: {
          // Edge returns URLs built from the runtime's internal SUPABASE_URL.
          'urls': [
            'http://kong:8000/storage/v1/object/sign/profile-photos/u/1.jpg?token=abc',
          ],
        },
        status: 200,
      ),
    );

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    // Origin swapped to the client's; path + ?token preserved verbatim.
    expect(urls, [
      'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/u/1.jpg?token=abc',
    ]);
  });

  test('signedUrlsOf returns empty list when urls missing', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    stubStorageUrl(client, 'http://10.0.2.2:54321/storage/v1');
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {}, status: 200));

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    expect(urls, isEmpty);
  });

  test('signedUrlsOf returns empty list when invoke throws (blocked 403 / edge error)', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body')))
        .thenThrow(const FunctionException(status: 403, details: {'urls': <String>[]}));

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    expect(urls, const <String>[]);
  });

  group('rebaseOrigin (pure helper)', () {
    final base = Uri.parse('http://10.0.2.2:54321/storage/v1');

    test('swaps host+port, keeps path and query intact', () {
      final out = PhotoRepository.rebaseOrigin(
        'http://kong:8000/storage/v1/object/sign/profile-photos/u/1.jpg?token=abc',
        base,
      );
      expect(
        out,
        'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/u/1.jpg?token=abc',
      );
    });

    test('is a no-op when the origin already matches', () {
      const url =
          'http://10.0.2.2:54321/storage/v1/object/sign/profile-photos/u/1.jpg?token=abc';
      expect(PhotoRepository.rebaseOrigin(url, base), url);
    });

    test('fully adopts a default-port base, dropping the incoming port', () {
      // base has no explicit port (https default 443); incoming has :8000.
      // The result must carry base's origin with NO :port artifact, and must
      // NOT graft the incoming :8000 onto base's host.
      final prodBase = Uri.parse('https://proj.supabase.co/storage/v1');
      final out = PhotoRepository.rebaseOrigin(
        'http://kong:8000/x?token=t',
        prodBase,
      );
      expect(out, 'https://proj.supabase.co/x?token=t');
    });

    test('returns the input as-is when it cannot be parsed', () {
      const bad = '::: not a url :::';
      expect(PhotoRepository.rebaseOrigin(bad, base), bad);
    });
  });

  test('uploadPhoto uploads then calls set_my_photo_paths with the appended list', () async {
    final client = MockSupabaseClient();
    final auth = _MockGoTrue();
    final storage = _MockPhotoStorage();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_FakeUser('uid-1'));
    when(() => storage.upload(any(), any())).thenAnswer((_) async {});
    when(() => client.rpc('set_my_photo_paths', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));

    final repo = PhotoRepository(client, storage: storage);
    final result = await repo.uploadPhoto(
      Uint8List.fromList([1, 2, 3]),
      slot: 1,
      current: const ['uid-1/0_100.jpg'],
    );

    // The uploaded path is '{uid}/{slot}_{millis}.jpg'; millis is time-based so we
    // capture it and assert the shape, then assert the RPC got current + new path.
    final captured =
        verify(() => storage.upload(captureAny(), any())).captured.single as String;
    expect(captured, startsWith('uid-1/1_'));
    expect(captured, endsWith('.jpg'));

    expect(result, ['uid-1/0_100.jpg', captured]);
    verify(() => client.rpc('set_my_photo_paths', params: {
          'p_paths': ['uid-1/0_100.jpg', captured],
        })).called(1);
  });

  // [AUDIT L6] RPC lưu path fail sau khi upload OK → file mồ côi trong bucket
  // (không path nào trỏ tới). Repo phải dọn best-effort rồi ném lại lỗi.
  test('uploadPhoto dọn file mồ côi khi RPC lưu path fail', () async {
    final client = MockSupabaseClient();
    final auth = _MockGoTrue();
    final storage = _MockPhotoStorage();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_FakeUser('u1'));
    when(() => storage.upload(any(), any())).thenAnswer((_) async {});
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => client.rpc('set_my_photo_paths', params: any(named: 'params')))
        .thenThrow(StateError('net'));

    final repo = PhotoRepository(client, storage: storage);
    await expectLater(
      repo.uploadPhoto(Uint8List.fromList([1]), slot: 0),
      throwsStateError,
    );

    final removed =
        verify(() => storage.remove(captureAny())).captured.single as List;
    expect(removed, hasLength(1));
    expect(removed.single as String, startsWith('u1/0_'));
  });

  test('removePhoto removes from storage then calls set_my_photo_paths with the pruned list', () async {
    final client = MockSupabaseClient();
    final storage = _MockPhotoStorage();
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => client.rpc('set_my_photo_paths', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk(null));

    final repo = PhotoRepository(client, storage: storage);
    final result = await repo.removePhoto(
      'uid-1/1_200.jpg',
      current: const ['uid-1/0_100.jpg', 'uid-1/1_200.jpg'],
    );

    expect(result, ['uid-1/0_100.jpg']);
    verify(() => storage.remove(['uid-1/1_200.jpg'])).called(1);
    verify(() => client.rpc('set_my_photo_paths', params: {
          'p_paths': ['uid-1/0_100.jpg'],
        })).called(1);
  });
}
