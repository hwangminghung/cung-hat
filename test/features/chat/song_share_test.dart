import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/domain/song_share.dart';
import 'package:cung_hat/features/chat/presentation/song_share_widgets.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';

void main() {
  test('encode/isSongShare/label đúng quy ước prefix ♪', () {
    final body = encodeSongShare('Ước Gì', 'Mỹ Tâm');
    expect(body, '♪ Ước Gì · Mỹ Tâm');
    expect(isSongShare(body), isTrue);
    expect(isSongShare('tin nhắn thường'), isFalse);
    expect(songShareLabel(body), 'Ước Gì · Mỹ Tâm');
  });

  testWidgets('SongShareContent render label + icon nốt nhạc', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SongShareContent(
            body: encodeSongShare('Ước Gì', 'Mỹ Tâm'),
            mine: false,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('song_share_content')), findsOneWidget);
    expect(find.text('Ước Gì · Mỹ Tâm'), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });

  testWidgets('sheet Gửi bài tủ liệt kê bài của mình và trả body encode', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBaituProvider.overrideWith((ref) async => ['s2']),
          songsProvider.overrideWith(
            (ref) async => const [
              Song(id: 's1', title: 'Lạc Trôi', artist: 'Sơn Tùng M-TP'),
              Song(id: 's2', title: 'Ước Gì', artist: 'Mỹ Tâm'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    picked = await showSongShareSheet(context);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Gửi bài tủ'), findsOneWidget);
    // Chỉ bài TỦ CỦA MÌNH (s2) — không phải cả catalog.
    expect(find.text('Ước Gì'), findsOneWidget);
    expect(find.text('Lạc Trôi'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('share_song_s2')));
    await tester.pumpAndSettle();
    expect(picked, '♪ Ước Gì · Mỹ Tâm');
  });
}
