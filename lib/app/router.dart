import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/moderation_screen.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/billing/presentation/store_screen.dart';
import '../features/discovery/presentation/doi_deck_screen.dart';
import '../features/discovery/presentation/likes_screen.dart';
import '../features/discovery/presentation/likes_teaser_screen.dart';
import '../features/discovery/presentation/theme_board_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/keo/presentation/create_keo_screen.dart';
import '../features/keo/presentation/keo_chat_screen.dart';
import '../features/keo/presentation/keo_detail_screen.dart';
import '../features/legal/presentation/legal_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/onboarding/presentation/onboarding_photos_screen.dart';
import '../features/keo/presentation/shared_keo_screen.dart';
import '../features/plan/presentation/plan_screen.dart';
import '../features/plan/presentation/shared_plan_screen.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/profile/domain/profile.dart';
import '../features/settings/presentation/blocked_users_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'deep_link.dart';
import 'home_shell.dart';

/// Maps the profile fetch state to the tri-state [authRedirect] input.
///
/// Order matters: a refresh (after invalidate on account switch) KEEPS the
/// previous user's value via Riverpod's copyWithPrevious, so while loading
/// the answer is "unknown" — the stale identity must never decide routing.
/// A resolved error also refuses the stale value: /onboarding is the safer
/// wrong answer and self-corrects on the next successful fetch.
bool? hasProfileOf(AsyncValue<Profile?> profile) {
  if (profile.isLoading) return null;
  if (profile.hasError) return false;
  return profile.value != null;
}

/// Pure redirect decision — unit-tested in isolation.
///
/// [hasProfile] is tri-state: `null` means the profile fetch hasn't resolved
/// yet — hold the current location and wait for the next router refresh
/// instead of guessing (guessing /onboarding causes a visible flash for
/// users who do have a profile).
String? authRedirect({
  required bool signedIn,
  required bool? hasProfile,
  required String location,
}) {
  final authArea = location == '/auth' || location == '/otp';
  final publicArea =
      authArea ||
      location.startsWith('/plan/shared') ||
      location.startsWith('/keo/shared');
  if (!signedIn) return publicArea ? null : '/auth';
  if (hasProfile == null) return null;
  if (!hasProfile) return location == '/onboarding' ? null : '/onboarding';
  // Profile exists: a user sitting on an auth/onboarding screen (e.g. right
  // after completing onboarding) must be sent home — otherwise they get stuck.
  if (authArea || location == '/onboarding') return '/';
  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      // [DEEPLINK] go_router cung nhan link tu platform va dua vao day duoi
      // dang URI THO khi app dang chay — dich truoc moi thu khac, neu khong
      // user thay "Page Not Found". Xem normalizeDeepLinkLocation.
      final fromLink = normalizeDeepLinkLocation(state.uri.toString());
      if (fromLink != null) return fromLink;
      // Read the session straight from Supabase: it is set BEFORE the auth
      // event fires, while derived providers may still hold a stale value
      // when this runs synchronously inside the refresh notification.
      final signedIn = ref.read(authRepositoryProvider).currentSession != null;
      return authRedirect(
        signedIn: signedIn,
        hasProfile: hasProfileOf(ref.read(myProfileProvider)),
        location: state.uri.path,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/auth', builder: (_, _) => const PhoneScreen()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
      // P1-6: bước ảnh optional SAU submit — route con nên authRedirect
      // (match đúng chuỗi '/onboarding') không đá về home.
      GoRoute(
        path: '/onboarding/photos',
        builder: (_, _) => const OnboardingPhotosScreen(),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const ModerationScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/settings/blocked',
        builder: (_, _) => const BlockedUsersScreen(),
      ),
      GoRoute(path: '/store', builder: (_, _) => const StoreScreen()),
      GoRoute(path: '/likes', builder: (_, _) => const LikesScreen()),
      GoRoute(
        path: '/likes-teaser',
        builder: (_, _) => const LikesTeaserScreen(),
      ),
      GoRoute(path: '/explore', builder: (_, _) => const ThemeBoardScreen()),
      GoRoute(
        path: '/explore/:genre',
        // DoiDeckScreen tự dựng Scaffold riêng — không bọc thêm Scaffold ở đây.
        builder: (_, s) => DoiDeckScreen(genre: s.pathParameters['genre']),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, _) => const LegalScreen(doc: LegalDoc.privacy),
      ),
      GoRoute(
        path: '/legal/tos',
        builder: (_, _) => const LegalScreen(doc: LegalDoc.tos),
      ),
      GoRoute(
        path: '/plan/shared/:token',
        builder: (_, s) => SharedPlanScreen(token: s.pathParameters['token']!),
      ),
      GoRoute(path: '/keo/create', builder: (_, _) => const CreateKeoScreen()),
      GoRoute(
        path: '/keo/shared/:token',
        builder: (_, s) => SharedKeoScreen(token: s.pathParameters['token']!),
      ),
      GoRoute(
        path: '/keo/chat/:id',
        builder: (_, s) => KeoChatScreen(keoId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/keo/plan/:id',
        builder: (_, s) => PlanScreen(
          keoId: s.pathParameters['id']!,
          isHost: s.uri.queryParameters['host'] == '1',
        ),
      ),
      GoRoute(
        path: '/keo/:id',
        builder: (_, s) => KeoDetailScreen(
          keoId: s.pathParameters['id']!,
          title: s.uri.queryParameters['title'] ?? 'Kèo',
        ),
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (_, s) => ChatScreen(
          matchId: s.pathParameters['matchId']!,
          otherName: s.uri.queryParameters['name'] ?? '',
        ),
      ),
    ],
  );
});

/// Bridges Riverpod auth/profile changes to go_router refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (prev, next) {
      // The cached profile belongs to the previous session (or to "signed
      // out"). Refetch it on sign-in/sign-out so the redirect doesn't sit
      // on a stale value waiting for Riverpod's retry backoff.
      final wasSignedIn = prev?.value?.session != null;
      final nowSignedIn = next.value?.session != null;
      if (wasSignedIn != nowSignedIn) ref.invalidate(myProfileProvider);
      notifyListeners();
    });
    ref.listen(myProfileProvider, (_, _) => notifyListeners());
  }
}
