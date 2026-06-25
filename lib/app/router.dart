import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/moderation_screen.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/billing/presentation/store_screen.dart';
import '../features/discovery/presentation/likes_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/keo/presentation/create_keo_screen.dart';
import '../features/keo/presentation/keo_chat_screen.dart';
import '../features/keo/presentation/keo_detail_screen.dart';
import '../features/legal/presentation/legal_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/plan/presentation/plan_screen.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'home_shell.dart';

/// Pure redirect decision — unit-tested in isolation.
String? authRedirect({
  required bool signedIn,
  required bool hasProfile,
  required String location,
}) {
  final authArea = location == '/auth' || location == '/otp';
  if (!signedIn) return authArea ? null : '/auth';
  if (!hasProfile) return location == '/onboarding' ? null : '/onboarding';
  if (authArea) return '/';
  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final hasProfile = ref.read(myProfileProvider).value != null;
      return authRedirect(
        signedIn: signedIn, hasProfile: hasProfile, location: state.uri.path,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/auth', builder: (_, _) => const PhoneScreen()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
      GoRoute(path: '/admin', builder: (_, _) => const ModerationScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/store', builder: (_, _) => const StoreScreen()),
      GoRoute(path: '/likes', builder: (_, _) => const LikesScreen()),
      GoRoute(path: '/legal/privacy', builder: (_, _) => const LegalScreen(assetPath: 'assets/legal/privacy_vi.md', title: 'Chính sách bảo mật')),
      GoRoute(path: '/legal/tos', builder: (_, _) => const LegalScreen(assetPath: 'assets/legal/tos_vi.md', title: 'Điều khoản sử dụng')),
      GoRoute(path: '/keo/create', builder: (_, _) => const CreateKeoScreen()),
      GoRoute(path: '/keo/chat/:id', builder: (_, s) => KeoChatScreen(keoId: s.pathParameters['id']!)),
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
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(myProfileProvider, (_, _) => notifyListeners());
  }
}
