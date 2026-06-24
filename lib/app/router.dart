import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/keo/presentation/create_keo_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/profile/application/profile_providers.dart';
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
      GoRoute(path: '/keo/create', builder: (_, _) => const CreateKeoScreen()),
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
