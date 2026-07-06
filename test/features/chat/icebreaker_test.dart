import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

class _MockChatRepo extends Mock implements ChatRepository {}

class _MockDiscoveryRepo extends Mock implements DiscoveryRepository {}

const _candidate = Candidate(
  id: 'u2',
  displayName: 'Linh',
  age: 24,
  distanceBand: '1-3',
  sharedBaitu: ['Nơi Này Có Anh'],
  prompts: [
    {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
  ],
);

/// Stub the chat providers common to every case (history rỗng, no realtime,
/// markRead no-op) — matches chat_screen_test.dart's harness.
void _stubChatRepo(_MockChatRepo chatRepo) {
  when(() => chatRepo.history(any())).thenAnswer((_) async => <Message>[]);
  when(() => chatRepo.subscribe(any()))
      .thenAnswer((_) => const Stream<Message>.empty());
  when(() => chatRepo.markRead(any())).thenAnswer((_) async {});
}

void main() {
  testWidgets(
      'tap chat_profile_btn mở sheet hồ sơ người match, hiện tên + bài tủ/prompt',
      (tester) async {
    final chatRepo = _MockChatRepo();
    final discoveryRepo = _MockDiscoveryRepo();
    _stubChatRepo(chatRepo);
    when(() => discoveryRepo.getMatchProfile('t1'))
        .thenAnswer((_) async => _candidate);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepo),
        discoveryRepositoryProvider.overrideWithValue(discoveryRepo),
        signedUrlsProvider('u2').overrideWith((ref) async => const <String>[]),
      ],
      child: const MaterialApp(
        home: ChatScreen(matchId: 't1', otherName: 'Linh'),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat_profile_btn')));
    await tester.pumpAndSettle();

    verify(() => discoveryRepo.getMatchProfile('t1')).called(1);
    expect(find.text('Linh, 24'), findsOneWidget);
    expect(find.text('Nơi Này Có Anh'), findsOneWidget);
    expect(find.text('Bài mình luôn giành mic là…'), findsOneWidget);
    // Sheet hiện chế độ icebreaker: KHÔNG có nút THÍCH/BỎ QUA (đã match rồi).
    expect(find.byKey(const Key('detail_like_btn')), findsNothing);
    expect(find.byKey(const Key('detail_pass_btn')), findsNothing);
  });

  testWidgets(
      'tap quote_baitu_0 đóng sheet + prefill composer bắt đầu bằng "Về bài"',
      (tester) async {
    final chatRepo = _MockChatRepo();
    final discoveryRepo = _MockDiscoveryRepo();
    _stubChatRepo(chatRepo);
    when(() => discoveryRepo.getMatchProfile('t1'))
        .thenAnswer((_) async => _candidate);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepo),
        discoveryRepositoryProvider.overrideWithValue(discoveryRepo),
        signedUrlsProvider('u2').overrideWith((ref) async => const <String>[]),
      ],
      child: const MaterialApp(
        home: ChatScreen(matchId: 't1', otherName: 'Linh'),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat_profile_btn')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('quote_baitu_0')));
    await tester.tap(find.byKey(const Key('quote_baitu_0')));
    await tester.pumpAndSettle();

    // Sheet đã đóng: không còn nút quote_baitu_0 trên cây widget.
    expect(find.byKey(const Key('quote_baitu_0')), findsNothing);

    final composer = tester.widget<TextField>(find.byType(TextField));
    expect(composer.controller!.text, startsWith('Về bài'));
    expect(composer.controller!.text, 'Về bài "Nơi Này Có Anh" của bạn: ');
  });

  testWidgets(
      'getMatchProfile trả null (đối phương xoá tài khoản) → SnackBar "Hồ sơ không còn."',
      (tester) async {
    final chatRepo = _MockChatRepo();
    final discoveryRepo = _MockDiscoveryRepo();
    _stubChatRepo(chatRepo);
    when(() => discoveryRepo.getMatchProfile('t1'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepo),
        discoveryRepositoryProvider.overrideWithValue(discoveryRepo),
      ],
      child: const MaterialApp(
        home: ChatScreen(matchId: 't1', otherName: 'Linh'),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat_profile_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ không còn.'), findsOneWidget);
  });
}
