import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
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
      GoRoute(path: '/onboarding', builder: (_, _) => const _OnboardingPlaceholder()),
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

/// Replaced by the real onboarding flow in P0.3.
class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Onboarding — P0.3', textDirection: TextDirection.ltr));
}
