import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/domain/like_teaser.dart';
import 'package:cung_hat/features/discovery/presentation/likes_teaser_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';

class _FakeLocationService extends Mock implements LocationService {}

// Ảnh mosaic: URL bogus — HttpClient mặc định của flutter_test trả 400 nên
// errorBuilder (fallback gradient + person) phải render, đúng đường degrade
// thật khi signed URL hết hạn.
const _teasers = [
  LikeTeaser(
    teaserUrl: 'http://bogus.local/storage/v1/object/sign/x/teaser.jpg?token=t',
    age: 24,
    verified: true,
    sharedGenre: 'ballad',
  ),
  LikeTeaser(teaserUrl: null, age: null, verified: false, sharedGenre: null),
];

Widget _screenHost(List<LikeTeaser> teasers) => ProviderScope(
      overrides: [
        likesTeaserProvider.overrideWith((ref) => Future.value(teasers)),
      ],
      child: const MaterialApp(home: LikesTeaserScreen()),
    );

/// Host HomeShell trong GoRouter thật (mirror keo_board_gate_test) để verify
/// điều hướng tile 'Ai đã thích bạn': free → màn teaser, entitled → /likes.
Widget _shellHost({
  required Set<String> entitlements,
  required _FakeLocationService fakeLoc,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/likes-teaser', builder: (_, _) => const LikesTeaserScreen()),
      GoRoute(
        path: '/likes',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('likes-stub'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      candidatesProvider(null).overrideWith((ref) => Future.value(<Candidate>[])),
      locationServiceProvider.overrideWithValue(fakeLoc),
      openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
      entitlementsProvider.overrideWith((ref) async => entitlements),
      likesTeaserProvider.overrideWith((ref) => Future.value(<LikeTeaser>[])),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
      '2 teaser → 2 card mosaic + chip tuổi/genre, tap unlock mở sheet Pro seeLikes',
      (tester) async {
    await tester.pumpWidget(_screenHost(_teasers));
    await tester.pumpAndSettle();

    expect(find.text('2 người đã thích bạn'), findsOneWidget);
    expect(find.byKey(const Key('teaser_card_0')), findsOneWidget);
    expect(find.byKey(const Key('teaser_card_1')), findsOneWidget);
    // Chip: tuổi của card 0, '?' cho card thiếu dob, genre chung, tick verified.
    expect(find.text('24'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('#ballad'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    // Card 0: URL bogus → errorBuilder fallback; card 1: null-photo → fallback
    // trực tiếp — cả 2 đều là icon person trên gradient, KHÔNG ảnh gốc nào.
    expect(find.byIcon(Icons.person_rounded), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('teaser_unlock_btn')));
    await tester.pumpAndSettle();
    // Sheet đúng biến thể seeLikes.
    expect(find.text('Xem ai đã thích bạn'), findsOneWidget);
  });

  testWidgets('rỗng → EmptyState "Chưa có ai thích bạn"', (tester) async {
    await tester.pumpWidget(_screenHost(const []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có ai thích bạn'), findsOneWidget);
    expect(
      find.text('Hoàn thiện hồ sơ để được thấy nhiều hơn nhé.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('teaser_unlock_btn')), findsNothing);
  });

  testWidgets(
      'FREE user: tap tile Ai đã thích bạn → điều hướng màn teaser (KHÔNG mở sheet trực tiếp)',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      _shellHost(entitlements: const <String>{}, fakeLoc: fakeLoc),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ai đã thích bạn'));
    await tester.pumpAndSettle();

    expect(find.byType(LikesTeaserScreen), findsOneWidget);
    // Hành vi CŨ (mở ProUpsellSheet ngay tại tile) không còn: sheet giờ nằm
    // sau CTA trong màn teaser, không bung thẳng từ home.
    expect(find.text('Xem ai đã thích bạn'), findsNothing);
  });

  testWidgets('PRO user: tap tile Ai đã thích bạn → /likes như cũ',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => LocationCaptureStatus.success);
    await tester.pumpWidget(
      _shellHost(entitlements: const <String>{'pro'}, fakeLoc: fakeLoc),
    );
    await tester.pumpAndSettle();

    // hasEntitlementProvider đọc entitlementsProvider async — warm nó như
    // keo_board_gate_test (shell thật luôn có billing warm sẵn).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeShell)),
    );
    await container.read(entitlementsProvider.future);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ai đã thích bạn'));
    await tester.pumpAndSettle();

    expect(find.text('likes-stub'), findsOneWidget);
    expect(find.byType(LikesTeaserScreen), findsNothing);
  });
}
