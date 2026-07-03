import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/photos/data/photo_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

class _MockGoTrue extends Mock implements GoTrueClient {}

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

  test('signedUrlsOf invokes sign-photo with target_id and returns urls', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body'))).thenAnswer(
      (_) async => FunctionResponse(
        data: {
          'urls': ['https://a', 'https://b'],
        },
        status: 200,
      ),
    );

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    expect(urls, ['https://a', 'https://b']);
    verify(() => fns.invoke('sign-photo', body: {'target_id': 'user-9'})).called(1);
  });

  test('signedUrlsOf returns empty list when urls missing', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('sign-photo', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {}, status: 200));

    final repo = PhotoRepository(client, storage: _MockPhotoStorage());
    final urls = await repo.signedUrlsOf('user-9');

    expect(urls, isEmpty);
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
