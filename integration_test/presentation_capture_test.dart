import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
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
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAnalytics extends AnalyticsService {
  @override
  Future<void> log(String name, [Map<String, Object>? parameters]) async {}
}

class _InMemoryAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryChatRepository implements ChatRepository {
  @override
  Future<void> markRead(String threadId) async {}

  @override
  Future<void> markKeoRead(String keoId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<bool> recordSwipe(String targetId, String direction) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryLocationService implements LocationService {
  @override
  Future<LocationCaptureStatus> captureAndPush() async =>
      LocationCaptureStatus.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryPlanRepository implements PlanRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

Widget _captureApp(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: true, textScaler: TextScaler.noScaling),
      child: child!,
    ),
    home: home,
  );
}

Widget _phoneFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_InMemoryAuthRepository()),
      ],
      child: const PhoneScreen(),
    ),
  );
}

Future<Widget> _otpFixture() async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_InMemoryAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).sendOtp('+84900000001');
  return _captureApp(
    UncontrolledProviderScope(container: container, child: const OtpScreen()),
  );
}

Widget _onboardingFixture() {
  return _captureApp(
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
        analyticsProvider.overrideWithValue(_InMemoryAnalytics()),
      ],
      child: const OnboardingFlow(),
    ),
  );
}

Widget _deckFixture() {
  SharedPreferences.setMockInitialValues({'deck_swipe_coach_seen': true});
  return _captureApp(
    ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(_InMemoryAnalytics()),
        discoveryRepositoryProvider.overrideWithValue(
          _InMemoryDiscoveryRepository(),
        ),
        locationServiceProvider.overrideWithValue(_InMemoryLocationService()),
        candidatesProvider(
          null,
        ).overrideWith((ref) async => const [_candidate]),
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
    ),
  );
}

Widget _candidateDetailFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        signedUrlsProvider(
          _candidate.id,
        ).overrideWith((ref) async => const <String>[]),
        songsProvider.overrideWith((ref) async => _songs),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(
          child: CandidateDetailSheet(
            candidate: _candidate,
            onPass: _noop,
            onLike: _noop,
          ),
        ),
      ),
    ),
  );
}

Widget _celebrationFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [songsProvider.overrideWith((ref) async => _songs)],
      child: const MatchCelebration(
        otherName: 'Linh',
        myName: 'Minh',
        sharedBaitu: ['song-1'],
        onChat: _noop,
        onContinue: _noop,
      ),
    ),
  );
}

Widget _themesFixture() {
  return _captureApp(
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

Widget _keoBoardFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        openKeosProvider.overrideWith((ref) async => const [_keo]),
        entitlementsProvider.overrideWith((ref) async => const <String>{}),
      ],
      child: const KeoBoardScreen(),
    ),
  );
}

Widget _keoMatchFixture() {
  return _captureApp(
    KeoMatchSheet(
      suggestions: const [_suggestion],
      onJoin: (_) async {},
      onCreate: (_) async {},
    ),
  );
}

Widget _createKeoFixture() {
  return _captureApp(
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

Widget _keoDetailFixture() {
  return _captureApp(
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

Widget _inboxFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        inboxProvider.overrideWith(
          (ref) async => [
            MatchSummary(
              matchId: 'match-1',
              otherId: 'candidate',
              otherName: 'Linh',
              unread: 2,
              lastSenderId: 'candidate',
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

Widget _chatFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_InMemoryChatRepository()),
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

Widget _keoChatFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_InMemoryChatRepository()),
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

Widget _profileFixture() {
  return _captureApp(
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

Widget _planFixture() {
  return _captureApp(
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

Widget _paymentFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [
        planRepositoryProvider.overrideWithValue(_InMemoryPlanRepository()),
      ],
      child: const Scaffold(
        body: Center(
          child: BookingButton(planId: 'plan-1', venueId: 'venue-1'),
        ),
      ),
    ),
  );
}

Widget _storeFixture() {
  return _captureApp(
    ProviderScope(
      overrides: [storeProductsProvider.overrideWith((ref) async => _catalog)],
      child: const StoreScreen(),
    ),
  );
}

Widget _settingsFixture() {
  SharedPreferences.setMockInitialValues({});
  return _captureApp(
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

void _noop() {}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Widget app,
    required Finder screen,
  }) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    if (!surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      addTearDown(() => surfaceConverted = false);
      await tester.pumpAndSettle();
    }
    expect(screen, findsOneWidget);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot(name);
  }

  Future<void> captureOnboarding(
    WidgetTester tester, {
    required int step,
    required String name,
    required Key screenKey,
  }) async {
    final app = _onboardingFixture();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    for (var current = 0; current < step; current++) {
      await tester.tap(find.byKey(const Key('onb_continue')));
      await tester.pumpAndSettle();
    }
    await capture(tester, name: name, app: app, screen: find.byKey(screenKey));
  }

  testWidgets('captures 01-login from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '01-login',
      app: _phoneFixture(),
      screen: find.byKey(const Key('screen_01_login')),
    );
  });

  testWidgets('captures 02-otp from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '02-otp',
      app: await _otpFixture(),
      screen: find.byKey(const Key('screen_02_otp')),
    );
  });

  testWidgets('captures 03-onboarding-dob after zero flow advances', (
    tester,
  ) async {
    await captureOnboarding(
      tester,
      step: 0,
      name: '03-onboarding-dob',
      screenKey: const Key('screen_03_onboarding_dob'),
    );
  });

  testWidgets('captures 04-onboarding-consent after one flow advance', (
    tester,
  ) async {
    await captureOnboarding(
      tester,
      step: 1,
      name: '04-onboarding-consent',
      screenKey: const Key('screen_04_onboarding_consent'),
    );
  });

  testWidgets('captures 05-onboarding-profile after two flow advances', (
    tester,
  ) async {
    await captureOnboarding(
      tester,
      step: 2,
      name: '05-onboarding-profile',
      screenKey: const Key('screen_05_onboarding_profile'),
    );
  });

  testWidgets('captures 06-onboarding-music-taste after three flow advances', (
    tester,
  ) async {
    await captureOnboarding(
      tester,
      step: 3,
      name: '06-onboarding-music-taste',
      screenKey: const Key('screen_06_onboarding_music_taste'),
    );
  });

  testWidgets('captures 07-doi-deck from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '07-doi-deck',
      app: _deckFixture(),
      screen: find.byKey(const Key('screen_07_doi_deck')),
    );
  });

  testWidgets('captures 08-doi-profile-detail from the production sheet', (
    tester,
  ) async {
    await capture(
      tester,
      name: '08-doi-profile-detail',
      app: _candidateDetailFixture(),
      screen: find.byKey(const Key('screen_08_doi_profile_detail')),
    );
  });

  testWidgets('captures 09-match-celebration from its production root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '09-match-celebration',
      app: _celebrationFixture(),
      screen: find.byKey(const Key('screen_09_match_celebration')),
    );
  });

  testWidgets('captures 10-explore-themes from its production root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '10-explore-themes',
      app: _themesFixture(),
      screen: find.byKey(const Key('screen_10_explore_themes')),
    );
  });

  testWidgets('captures 11-keo-board from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '11-keo-board',
      app: _keoBoardFixture(),
      screen: find.byKey(const Key('screen_11_keo_board')),
    );
  });

  testWidgets('captures 12-keo-auto-match from the production sheet', (
    tester,
  ) async {
    await capture(
      tester,
      name: '12-keo-auto-match',
      app: _keoMatchFixture(),
      screen: find.byKey(const Key('screen_12_keo_auto_match')),
    );
  });

  testWidgets('captures 13-create-keo from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '13-create-keo',
      app: _createKeoFixture(),
      screen: find.byKey(const Key('screen_13_create_keo')),
    );
  });

  testWidgets('captures 14-keo-detail from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '14-keo-detail',
      app: _keoDetailFixture(),
      screen: find.byKey(const Key('screen_14_keo_detail')),
    );
  });

  testWidgets('captures 15-inbox from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '15-inbox',
      app: _inboxFixture(),
      screen: find.byKey(const Key('screen_15_inbox')),
    );
  });

  testWidgets('captures 16-chat-1to1 from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '16-chat-1to1',
      app: _chatFixture(),
      screen: find.byKey(const Key('screen_16_chat_1to1')),
    );
  });

  testWidgets('captures 17-keo-group-chat from its production root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '17-keo-group-chat',
      app: _keoChatFixture(),
      screen: find.byKey(const Key('screen_17_keo_group_chat')),
    );
  });

  testWidgets('captures 18-profile from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '18-profile',
      app: _profileFixture(),
      screen: find.byKey(const Key('screen_18_profile')),
    );
  });

  testWidgets('captures 19-plan from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '19-plan',
      app: _planFixture(),
      screen: find.byKey(const Key('screen_19_plan')),
    );
  });

  testWidgets('captures 20-booking-payment from the production sheet', (
    tester,
  ) async {
    final app = _paymentFixture();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BookingButton));
    await tester.pumpAndSettle();
    await capture(
      tester,
      name: '20-booking-payment',
      app: app,
      screen: find.byKey(const Key('screen_20_booking_payment')),
    );
  });

  testWidgets('captures 21-store from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '21-store',
      app: _storeFixture(),
      screen: find.byKey(const Key('screen_21_store')),
    );
  });

  testWidgets('captures 22-settings from its production screen root', (
    tester,
  ) async {
    await capture(
      tester,
      name: '22-settings',
      app: _settingsFixture(),
      screen: find.byKey(const Key('screen_22_settings')),
    );
  });
}
