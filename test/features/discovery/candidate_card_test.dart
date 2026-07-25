import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

const _cand = Candidate(
  id: 'u1',
  displayName: 'Linh',
  age: 24,
  distanceBand: '1-3',
  sharedGenres: ['ballad', 'kpop'],
  sharedBaitu: ['s1', 's2'],
  bio: 'Hát ballad về đêm',
);

const _candB = Candidate(
  id: 'u2',
  displayName: 'Mai',
  age: 27,
  distanceBand: '3-5',
  sharedGenres: ['rock'],
  sharedBaitu: ['s9'],
  bio: 'Rock cả tuần',
);

Widget _host({List<String> urls = const ['u1.jpg', 'u2.jpg', 'u3.jpg']}) {
  return ProviderScope(
    overrides: [signedUrlsProvider('u1').overrideWith((ref) async => urls)],
    child: MaterialApp(
      home: Scaffold(
        body: CandidateCard(candidate: _cand, onOpenDetail: () {}),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'ảnh 1: chip khoảng cách + bài tủ; tap phải → ảnh 2: genres; tiếp → bio',
    (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
      expect(find.textContaining('cùng 2 bài tủ'), findsOneWidget);
      expect(find.text('#ballad'), findsNothing);

      final photoArea = find.byKey(const Key('card_photo_area'));
      final rect = tester.getRect(photoArea);
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('#ballad'), findsOneWidget);
      expect(find.textContaining('Cách 1-3 km'), findsNothing);

      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Hát ballad về đêm'), findsOneWidget);

      // Ảnh cuối: tap phải lần nữa → clamp giữ nguyên, vẫn bio, không exception.
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Hát ballad về đêm'), findsOneWidget);

      await tester.tapAt(Offset(rect.left + 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('#ballad'), findsOneWidget);
    },
  );

  testWidgets(
    'đổi ứng viên cùng vị trí cây widget (không key) → chip reset về ảnh 1',
    (tester) async {
      // Mô phỏng CardSwiper: card dựng theo VỊ TRÍ, không key, nên khi deck tiến
      // A→B, Flutter tái dụng _CandidateCardState — didUpdateWidget phải reset
      // _photoIndex kẻo card của B mở màn bằng chip bio.
      var current = _cand;
      late StateSetter swap;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedUrlsProvider(
              'u1',
            ).overrideWith((ref) async => const ['a1.jpg', 'a2.jpg', 'a3.jpg']),
            signedUrlsProvider(
              'u2',
            ).overrideWith((ref) async => const ['b1.jpg', 'b2.jpg', 'b3.jpg']),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  swap = setState;
                  return CandidateCard(candidate: current, onOpenDetail: () {});
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A: tap tới ảnh 3 → hiện bio của A.
      final rect = tester.getRect(find.byKey(const Key('card_photo_area')));
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Hát ballad về đêm'), findsOneWidget);

      // Đổi sang B không đổi key/vị trí — State bị tái dụng.
      swap(() => current = _candB);
      await tester.pumpAndSettle();

      expect(find.text('Mai, 27'), findsOneWidget);
      expect(find.textContaining('Cách 3-5 km'), findsOneWidget);
      expect(find.text('Rock cả tuần'), findsNothing);
    },
  );

  testWidgets('nút ⓘ mở detail (callback)', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedUrlsProvider('u1').overrideWith((ref) async => ['u1.jpg']),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: _cand,
              onOpenDetail: () => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card_photo_area')), findsOneWidget);
    expect(find.byKey(const Key('card_detail_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('card_detail_btn')));
    expect(opened, isTrue);
  });

  testWidgets('<2 ảnh: chip gộp như cũ (distance + baitu + genres)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(urls: ['u1.jpg']));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
    expect(find.text('#ballad'), findsOneWidget);
  });

  testWidgets(
    'panel: activeToday + sharedGenres → hiện "Trực tuyến hôm nay" + chip #genre (mockup 07)',
    (tester) async {
      const candidate = Candidate(
        id: 'x',
        displayName: 'Linh',
        activeToday: true,
        sharedGenres: ['ballad', 'vpop'],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedUrlsProvider('x').overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CandidateCard(candidate: candidate, onOpenDetail: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trực tuyến hôm nay'), findsOneWidget);
      expect(find.text('#ballad'), findsOneWidget);
    },
  );

  testWidgets(
    'panel: không activeToday + sharedGenres rỗng → không hiện online/chip',
    (tester) async {
      const candidate = Candidate(id: 'y', displayName: 'Mai');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedUrlsProvider('y').overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CandidateCard(candidate: candidate, onOpenDetail: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trực tuyến hôm nay'), findsNothing);
      expect(find.text('#ballad'), findsNothing);
    },
  );

  test(
    'monogramTextColorOn: ink trên nền nhạt (tertiaryPop/pink), trắng trên nền đậm',
    () {
      expect(monogramTextColorOn(AppColors.tertiaryPop), AppColors.ink);
      expect(monogramTextColorOn(AppColors.pink), AppColors.ink);
      expect(monogramTextColorOn(AppColors.primary), AppColors.onPrimary);
    },
  );
}
