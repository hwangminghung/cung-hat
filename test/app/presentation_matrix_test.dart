import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/otp_screen.dart';
import 'package:cung_hat/features/auth/presentation/phone_screen.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/domain/music_themes.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_detail_sheet.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';
import 'package:cung_hat/features/discovery/presentation/theme_board_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/create_keo_screen.dart';
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';
import 'package:cung_hat/features/keo/presentation/keo_chat_screen.dart';
import 'package:cung_hat/features/keo/presentation/keo_detail_screen.dart';
import 'package:cung_hat/features/keo/presentation/keo_match_sheet.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_flow.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/booking_button.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/features/profile/presentation/profile_screen.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/analytics_fakes.dart';
import '../support/presentation_harness.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockLocationService extends Mock implements LocationService {}

class _MockPlanRepository extends Mock implements PlanRepository {}

class _PresentationConfig {
  const _PresentationConfig({
    required this.width,
    required this.textScale,
    required this.platform,
  });

  final double width;
  final double textScale;
  final TargetPlatform platform;

  String get label =>
      '${width.toInt()}dp/${textScale}x/${platform.name}/reduced-motion';
}

typedef _PumpScreen =
    Future<void> Function(WidgetTester tester, _PresentationConfig config);

typedef _FindAction = Finder Function();

class _PresentationTarget {
  const _PresentationTarget({
    required this.number,
    required this.key,
    required this.pump,
    required this.primaryAction,
    this.scrollPrimaryAction = false,
  });

  final int number;
  final Key key;
  final _PumpScreen pump;
  final _FindAction primaryAction;
  final bool scrollPrimaryAction;

  String get label => 'screen_${number.toString().padLeft(2, '0')}';
}

const _candidate = Candidate(
  id: 'candidate',
  displayName: 'Linh',
  age: 24,
  distanceBand: '1-3',
  sharedGenres: ['ballad', 'vpop'],
  sharedBaitu: ['song-1', 'song-2'],
  verified: true,
  activeToday: true,
  bio: 'Mê song ca và những buổi karaoke cuối tuần.',
);

const _songs = <Song>[
  Song(id: 'song-1', title: 'Nơi Này Có Anh', artist: 'Sơn Tùng M-TP'),
  Song(id: 'song-2', title: 'Lạc Trôi', artist: 'Sơn Tùng M-TP'),
];

const _keo = Keo(
  id: 'keo-1',
  title: 'Kèo V-Pop tối nay cùng hội bạn',
  areaLabel: 'Music Box Thủ Đức',
  distanceBand: '1-3',
  timeWindowStart: '2026-07-20T19:00:00Z',
  timeWindowEnd: '2026-07-20T22:00:00Z',
  sizeTarget: 5,
  slotsFilled: 2,
  genres: ['vpop', 'ballad'],
  hostName: 'Minh',
  memberNames: ['Minh', 'Linh'],
);

const _suggestion = KeoMatchSuggestion(
  suggestionType: 'existing_keo',
  keoId: 'keo-1',
  title: 'Kèo V-Pop hợp gu',
  areaLabel: 'Thủ Đức',
  distanceBand: '1-3',
  timeWindowStart: '2026-07-20T19:00:00Z',
  timeWindowEnd: '2026-07-20T22:00:00Z',
  sizeTarget: 5,
  slotsFilled: 2,
  genres: ['vpop'],
  hostName: 'Minh',
  reasonLabels: ['same_genre', 'nearby'],
);

const _catalog = <StoreProduct>[
  StoreProduct(
    sku: 'pro_android',
    type: 'pro',
    storeProductId: 'pro',
    priceMinor: 199000,
  ),
  StoreProduct(
    sku: 'boost_android',
    type: 'boost',
    storeProductId: 'boost',
    priceMinor: 49000,
  ),
  StoreProduct(
    sku: 'see_likes_android',
    type: 'see_likes',
    storeProductId: 'see_likes',
    priceMinor: 99000,
  ),
  StoreProduct(
    sku: 'filters_android',
    type: 'premium_filters',
    storeProductId: 'filters',
    priceMinor: 79000,
  ),
];

Future<void> _pump(
  WidgetTester tester,
  _PresentationConfig config,
  Widget child,
) async {
  await pumpPresentation(
    tester,
    child: child,
    size: Size(config.width, 852),
    textScale: config.textScale,
    platform: config.platform,
    disableAnimations: true,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPhone(WidgetTester tester, _PresentationConfig config) async {
  final repository = _MockAuthRepository();
  when(() => repository.sendOtp(any())).thenAnswer((_) async {});
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const PhoneScreen(),
    ),
  );
}

Future<void> _pumpOtp(WidgetTester tester, _PresentationConfig config) async {
  final repository = _MockAuthRepository();
  when(() => repository.sendOtp(any())).thenAnswer((_) async {});
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).sendOtp('+84900000001');
  await _pump(
    tester,
    config,
    UncontrolledProviderScope(container: container, child: const OtpScreen()),
  );
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  _PresentationConfig config,
  int step,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        genresProvider.overrideWith(
          (ref) async => const [
            Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop'),
          ],
        ),
        artistsProvider.overrideWith(
          (ref) async => const [Artist(id: 'artist-1', name: 'Mỹ Tâm')],
        ),
        songsProvider.overrideWith((ref) async => _songs),
        analyticsProvider.overrideWithValue(RecordingAnalytics()),
      ],
      child: const OnboardingFlow(),
    ),
  );
  for (var current = 0; current < step; current++) {
    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
  }
}

Future<void> _pumpDob(WidgetTester tester, _PresentationConfig config) =>
    _pumpOnboarding(tester, config, 0);

Future<void> _pumpConsent(WidgetTester tester, _PresentationConfig config) =>
    _pumpOnboarding(tester, config, 1);

Future<void> _pumpProfileStep(
  WidgetTester tester,
  _PresentationConfig config,
) => _pumpOnboarding(tester, config, 2);

Future<void> _pumpTasteStep(WidgetTester tester, _PresentationConfig config) =>
    _pumpOnboarding(tester, config, 3);

ProviderScope _deckFixture({
  required _MockDiscoveryRepository discoveryRepository,
  required _MockLocationService locationService,
}) {
  return ProviderScope(
    overrides: [
      analyticsProvider.overrideWithValue(RecordingAnalytics()),
      discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      locationServiceProvider.overrideWithValue(locationService),
      candidatesProvider(null).overrideWith((ref) async => const [_candidate]),
      discoveryPrefsProvider.overrideWith(
        (ref) async => (autoExpand: false, radiusKm: 50),
      ),
      openKeosProvider.overrideWith((ref) async => const <Keo>[]),
      signedUrlsProvider(
        _candidate.id,
      ).overrideWith((ref) async => const <String>[]),
      entitlementsProvider.overrideWith((ref) async => const <String>{}),
    ],
    child: const DoiDeckScreen(),
  );
}

Future<void> _pumpDeck(WidgetTester tester, _PresentationConfig config) async {
  SharedPreferences.setMockInitialValues({'deck_swipe_coach_seen': true});
  final locationService = _MockLocationService();
  when(
    () => locationService.captureAndPush(),
  ).thenAnswer((_) async => LocationCaptureStatus.success);
  final discoveryRepository = _MockDiscoveryRepository();
  when(
    () => discoveryRepository.recordSwipe(any(), any()),
  ).thenAnswer((_) async => false);
  await _pump(
    tester,
    config,
    _deckFixture(
      discoveryRepository: discoveryRepository,
      locationService: locationService,
    ),
  );
}

Future<void> _pumpCandidateDetail(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        signedUrlsProvider(
          _candidate.id,
        ).overrideWith((ref) async => const <String>[]),
        songsProvider.overrideWith((ref) async => _songs),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: CandidateDetailSheet(
            candidate: _candidate,
            onPass: () {},
            onLike: () {},
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpCelebration(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [songsProvider.overrideWith((ref) async => _songs)],
      child: MatchCelebration(
        otherName: 'Linh',
        myName: 'Minh',
        sharedBaitu: const ['song-1'],
        onChat: () {},
        onContinue: () {},
      ),
    ),
  );
}

Future<void> _pumpThemes(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        themeDeckCountsProvider.overrideWith(
          (ref) async => {for (final theme in musicThemes) theme.genreId: 12},
        ),
      ],
      child: const ThemeBoardScreen(),
    ),
  );
}

Future<void> _pumpKeoBoard(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        openKeosProvider.overrideWith((ref) async => const [_keo]),
        entitlementsProvider.overrideWith((ref) async => const <String>{}),
      ],
      child: const KeoBoardScreen(),
    ),
  );
}

Future<void> _pumpKeoMatch(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    KeoMatchSheet(
      suggestions: const [_suggestion],
      onJoin: (_) async {},
      onCreate: (_) async {},
    ),
  );
}

Future<void> _pumpCreateKeo(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        genresProvider.overrideWith(
          (ref) async => const [
            Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop'),
          ],
        ),
      ],
      child: const CreateKeoScreen(),
    ),
  );
}

Future<void> _pumpKeoDetail(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        keoRosterProvider(
          _keo.id,
        ).overrideWith((ref) async => const <KeoMember>[]),
        keoHeaderProvider(_keo.id).overrideWith((ref) async => _keo),
        myProfileProvider.overrideWith(
          (ref) async => const Profile(id: 'viewer', displayName: 'An'),
        ),
      ],
      child: const KeoDetailScreen(
        keoId: 'keo-1',
        title: 'Kèo V-Pop tối nay cùng hội bạn',
      ),
    ),
  );
}

Future<void> _pumpInbox(WidgetTester tester, _PresentationConfig config) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        inboxProvider.overrideWith(
          (ref) async => [
            MatchSummary(
              matchId: 'match-1',
              otherId: _candidate.id,
              otherName: 'Linh',
              unread: 2,
              lastSenderId: _candidate.id,
            ),
          ],
        ),
        myKeosProvider.overrideWith((ref) async => const [_keo]),
        myProfileProvider.overrideWith(
          (ref) async => const Profile(id: 'viewer', displayName: 'Minh'),
        ),
      ],
      child: const InboxScreen(onFindKeo: _noop),
    ),
  );
}

void _noop() {}

Future<void> _pumpChat(WidgetTester tester, _PresentationConfig config) async {
  final repository = _MockChatRepository();
  when(() => repository.markRead('match-1')).thenAnswer((_) async {});
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        messageHistoryProvider(
          'match-1',
        ).overrideWith((ref) async => const <Message>[]),
        liveMessagesProvider(
          'match-1',
        ).overrideWith((ref) => const Stream<Message>.empty()),
      ],
      child: const ChatScreen(matchId: 'match-1', otherName: 'Linh'),
    ),
  );
}

Future<void> _pumpKeoChat(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  final repository = _MockChatRepository();
  when(() => repository.markKeoRead(_keo.id)).thenAnswer((_) async {});
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        keoMessageHistoryProvider(
          _keo.id,
        ).overrideWith((ref) async => const <Message>[]),
        keoLiveMessagesProvider(
          _keo.id,
        ).overrideWith((ref) => const Stream<Message>.empty()),
        keoHeaderProvider(_keo.id).overrideWith((ref) async => _keo),
        keoRosterProvider(
          _keo.id,
        ).overrideWith((ref) async => const <KeoMember>[]),
      ],
      child: const KeoChatScreen(keoId: 'keo-1'),
    ),
  );
}

Future<void> _pumpProfile(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        myProfileProvider.overrideWith(
          (ref) async => const Profile(
            id: 'viewer',
            displayName: 'Minh',
            bio: 'Hát ballad và V-Pop.',
            photoPaths: ['one.jpg'],
          ),
        ),
        myTasteCountsProvider.overrideWith(
          (ref) async => const TasteCounts(3, 1, 1),
        ),
        entitlementsProvider.overrideWith((ref) async => const <String>{}),
      ],
      child: const ProfileScreen(),
    ),
  );
}

Future<void> _pumpPlan(WidgetTester tester, _PresentationConfig config) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        nearestVenuesProvider(_keo.id).overrideWith(
          (ref) async => const [
            VenueSuggestion(
              id: 'venue-1',
              name: 'Music Box Thủ Đức',
              address: '120 Võ Văn Ngân, Thủ Đức',
              distanceBand: '1-3',
              lat: 10.85,
              lng: 106.76,
            ),
          ],
        ),
        currentPlanProvider(_keo.id).overrideWith(
          (ref) async => Plan(
            id: 'plan-1',
            keoId: _keo.id,
            venueId: 'venue-1',
            scheduledAt: '2026-07-20T19:00:00Z',
            status: 'confirmed',
          ),
        ),
        keoMidpointProvider(_keo.id).overrideWith((ref) async => null),
      ],
      child: const PlanScreen(
        keoId: 'keo-1',
        isHost: true,
        useNativeMap: false,
      ),
    ),
  );
}

Future<void> _pumpPayment(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  final repository = _MockPlanRepository();
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [planRepositoryProvider.overrideWithValue(repository)],
      child: const Scaffold(
        body: Center(
          child: BookingButton(planId: 'plan-1', venueId: 'venue-1'),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(BookingButton));
  await tester.pumpAndSettle();
}

Future<void> _pumpStore(WidgetTester tester, _PresentationConfig config) async {
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [storeProductsProvider.overrideWith((ref) async => _catalog)],
      child: const StoreScreen(),
    ),
  );
}

Future<void> _pumpSettings(
  WidgetTester tester,
  _PresentationConfig config,
) async {
  SharedPreferences.setMockInitialValues({});
  await _pump(
    tester,
    config,
    ProviderScope(
      overrides: [
        myConsentsProvider.overrideWith(
          (ref) async => const <String, bool>{
            'location': true,
            'photos': true,
            'matching': true,
            'marketing': false,
            'cross_border': true,
          },
        ),
      ],
      child: const SettingsScreen(),
    ),
  );
}

final _targets = <_PresentationTarget>[
  _PresentationTarget(
    number: 1,
    key: const Key('screen_01_login'),
    pump: _pumpPhone,
    primaryAction: () => find.byKey(const Key('send_otp_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 2,
    key: const Key('screen_02_otp'),
    pump: _pumpOtp,
    primaryAction: () => find.byKey(const Key('verify_otp_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 3,
    key: const Key('screen_03_onboarding_dob'),
    pump: _pumpDob,
    primaryAction: () => find.byKey(const Key('onb_continue')),
  ),
  _PresentationTarget(
    number: 4,
    key: const Key('screen_04_onboarding_consent'),
    pump: _pumpConsent,
    primaryAction: () => find.byKey(const Key('onb_continue')),
  ),
  _PresentationTarget(
    number: 5,
    key: const Key('screen_05_onboarding_profile'),
    pump: _pumpProfileStep,
    primaryAction: () => find.byKey(const Key('onb_continue')),
  ),
  _PresentationTarget(
    number: 6,
    key: const Key('screen_06_onboarding_music_taste'),
    pump: _pumpTasteStep,
    primaryAction: () => find.byKey(const Key('onb_finish')),
  ),
  _PresentationTarget(
    number: 7,
    key: const Key('screen_07_doi_deck'),
    pump: _pumpDeck,
    primaryAction: () => find.byKey(const Key('deck_like_btn')),
  ),
  _PresentationTarget(
    number: 8,
    key: const Key('screen_08_doi_profile_detail'),
    pump: _pumpCandidateDetail,
    primaryAction: () => find.byKey(const Key('detail_like_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 9,
    key: const Key('screen_09_match_celebration'),
    pump: _pumpCelebration,
    primaryAction: () => find.byKey(const Key('match_chat_btn')),
  ),
  _PresentationTarget(
    number: 10,
    key: const Key('screen_10_explore_themes'),
    pump: _pumpThemes,
    primaryAction: () => find.byKey(const Key('theme_card_vpop')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 11,
    key: const Key('screen_11_keo_board'),
    pump: _pumpKeoBoard,
    primaryAction: () => find.widgetWithText(GradientButton, 'Tạo kèo'),
  ),
  _PresentationTarget(
    number: 12,
    key: const Key('screen_12_keo_auto_match'),
    pump: _pumpKeoMatch,
    primaryAction: () => find.byKey(const Key('keo_match_join_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 13,
    key: const Key('screen_13_create_keo'),
    pump: _pumpCreateKeo,
    primaryAction: () => find.byKey(const Key('create_keo_btn')),
  ),
  _PresentationTarget(
    number: 14,
    key: const Key('screen_14_keo_detail'),
    pump: _pumpKeoDetail,
    primaryAction: () => find.byKey(const Key('request_join_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 15,
    key: const Key('screen_15_inbox'),
    pump: _pumpInbox,
    primaryAction: () =>
        find.ancestor(of: find.text('Linh'), matching: find.byType(InkWell)),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 16,
    key: const Key('screen_16_chat_1to1'),
    pump: _pumpChat,
    primaryAction: () => find.byKey(const Key('send_btn')),
  ),
  _PresentationTarget(
    number: 17,
    key: const Key('screen_17_keo_group_chat'),
    pump: _pumpKeoChat,
    primaryAction: () => find.byKey(const Key('send_btn')),
  ),
  _PresentationTarget(
    number: 18,
    key: const Key('screen_18_profile'),
    pump: _pumpProfile,
    primaryAction: () => find
        .descendant(
          of: find.byKey(const Key('screen_18_profile')),
          matching: find.byType(ListTile),
        )
        .first,
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 19,
    key: const Key('screen_19_plan'),
    pump: _pumpPlan,
    primaryAction: () => find.byKey(const Key('directions_btn')),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 20,
    key: const Key('screen_20_booking_payment'),
    pump: _pumpPayment,
    primaryAction: () => find.byKey(const Key('booking_gw_momo')),
  ),
  _PresentationTarget(
    number: 21,
    key: const Key('screen_21_store'),
    pump: _pumpStore,
    primaryAction: () => find.descendant(
      of: find.byKey(const Key('store_product_premium_filters')),
      matching: find.byType(FilledButton),
    ),
    scrollPrimaryAction: true,
  ),
  _PresentationTarget(
    number: 22,
    key: const Key('screen_22_settings'),
    pump: _pumpSettings,
    primaryAction: () => find.byKey(const Key('lang_en')),
    scrollPrimaryAction: true,
  ),
];

Future<void> _makePrimaryActionReachable(
  WidgetTester tester,
  _PresentationTarget target,
) async {
  final action = target.primaryAction();
  expect(action, findsOneWidget, reason: '${target.label} primary action');

  if (target.scrollPrimaryAction) {
    final scrollable = find
        .ancestor(of: action, matching: find.byType(Scrollable))
        .first;
    expect(scrollable, findsOneWidget, reason: '${target.label} scroll owner');
    await tester.dragUntilVisible(
      action,
      scrollable,
      const Offset(0, -180),
      maxIteration: 30,
    );
    await tester.pump();
  }

  expect(
    action.hitTestable(),
    findsOneWidget,
    reason: '${target.label} primary action is not reachable',
  );
  final size = tester.getSize(action);
  expect(
    size.width,
    greaterThanOrEqualTo(44),
    reason: '${target.label} primary action width',
  );
  expect(
    size.height,
    greaterThanOrEqualTo(44),
    reason: '${target.label} primary action height',
  );
}

void _expectProductionPlatform(
  WidgetTester tester,
  _PresentationTarget target,
  TargetPlatform platform,
) {
  final context = tester.element(find.byKey(target.key));
  expect(
    Theme.of(context).platform,
    platform,
    reason: '${target.label} did not receive the requested platform',
  );
}

void main() {
  test('coverage registry contains every approved screen exactly once', () {
    expect(_targets, hasLength(22));
    expect([
      for (final target in _targets) target.number,
    ], List<int>.generate(22, (index) => index + 1));
    expect(
      {for (final target in _targets) target.key}.length,
      22,
      reason: 'duplicate screen key in presentation registry',
    );
  });

  for (final target in _targets) {
    group(target.label, () {
      for (final platform in presentationPlatforms) {
        for (final width in presentationWidths) {
          for (final textScale in presentationTextScales) {
            final config = _PresentationConfig(
              width: width,
              textScale: textScale,
              platform: platform,
            );
            testWidgets(config.label, (tester) async {
              await target.pump(tester, config);
              expect(
                find.byKey(target.key),
                findsOneWidget,
                reason: '${target.label} missing at ${config.label}',
              );
              _expectProductionPlatform(tester, target, platform);
              await _makePrimaryActionReachable(tester, target);
              expect(
                tester.takeException(),
                isNull,
                reason: '${target.label} overflowed at ${config.label}',
              );
            });
          }
        }
      }
    });
  }

  for (final target in _targets) {
    testWidgets('${target.label} semantics, contrast, and keyboard audit', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      const config = _PresentationConfig(
        width: 393,
        textScale: 1,
        platform: TargetPlatform.iOS,
      );
      await target.pump(tester, config);
      await _makePrimaryActionReachable(tester, target);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus,
        isNotNull,
        reason: '${target.label} has no keyboard-reachable control',
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  for (final action in const ['pass', 'like']) {
    testWidgets('screen_07 exposes a working pointer $action alternative', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'deck_swipe_coach_seen': true});
      final locationService = _MockLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);
      final repository = _MockDiscoveryRepository();
      when(
        () => repository.recordSwipe(any(), any()),
      ).thenAnswer((_) async => false);
      const config = _PresentationConfig(
        width: 393,
        textScale: 1,
        platform: TargetPlatform.android,
      );

      await _pump(
        tester,
        config,
        _deckFixture(
          discoveryRepository: repository,
          locationService: locationService,
        ),
      );
      await tester.tap(find.byKey(Key('deck_${action}_btn')));
      await tester.pumpAndSettle();

      verify(
        () => repository.recordSwipe(
          _candidate.id,
          action == 'pass' ? 'pass' : 'like',
        ),
      ).called(1);
      expect(tester.takeException(), isNull);
    });
  }
}
