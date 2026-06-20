# Cùng Hát — P0.2 Auth (Phone OTP) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phone-OTP (+84) authentication with a provider-agnostic Send-SMS hook, Supabase session management, and a go_router auth-redirect that routes unauthenticated → `/auth`, authenticated-without-profile → `/onboarding`, otherwise → `/`.

**Architecture:** Builds on P0. Supabase Auth phone provider; local dev uses `config.toml` **test OTP** (no real SMS). A `send-sms` Edge Function is scaffolded as the production hook target so a cheap VN provider can be dropped in later. Flutter: an `auth` feature (repository → controller → screens) plus an `authState` stream that drives the router's `redirect`.

**Tech Stack:** supabase_flutter Auth, Riverpod 3 (Notifier/StreamProvider), go_router redirect, Supabase Edge Functions (Deno), mocktail.

**Depends on P0:** `supabaseClientProvider` (`lib/core/providers/supabase_providers.dart`), `Profile` + `profileRepositoryProvider` + `myProfileProvider` (`lib/features/profile/...`), `lib/app/router.dart`, `lib/app/app.dart`, l10n in `lib/l10n/`.

---

### Task 1: Configure Supabase phone auth (local test OTP) + scaffold the Send-SMS hook

**Files:**
- Modify: `supabase/config.toml`
- Create: `supabase/functions/send-sms/index.ts`

- [ ] **Step 1: Enable phone auth + a local test OTP in config.toml**

Add/modify in `supabase/config.toml`:
```toml
[auth.sms]
enable_signup = true
enable_confirmations = true

# Local dev only: these numbers skip real SMS and accept the fixed code.
[auth.sms.test_otp]
84900000001 = "123456"

# Production hook target (NOT exercised locally because test_otp short-circuits SMS).
[auth.hook.send_sms]
enabled = false
uri = "http://host.docker.internal:54321/functions/v1/send-sms"
```

- [ ] **Step 2: Scaffold the provider-agnostic Send-SMS Edge Function**

Create `supabase/functions/send-sms/index.ts`:
```ts
// Production Send-SMS auth hook. Swap PROVIDER impl for a VN SMS gateway later.
// Secrets come from Edge env (SMS_API_KEY); never in the client.
Deno.serve(async (req) => {
  const { user, sms } = await req.json().catch(() => ({}));
  const phone = user?.phone ?? sms?.phone;
  const otp = sms?.otp;
  if (!phone || !otp) {
    return new Response(JSON.stringify({ error: "missing phone/otp" }), { status: 400 });
  }
  // TODO(prod): call the chosen VN provider here using Deno.env.get("SMS_API_KEY").
  console.log(`[send-sms] would send OTP ${otp} to ${phone}`);
  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 3: Apply config + restart the stack**

Run: `supabase stop` then `supabase start`
Expected: stack restarts; phone auth enabled. (Local OTP for `+84900000001` is `123456`.)

- [ ] **Step 4: Commit**

```
git add supabase/config.toml supabase/functions/send-sms/index.ts
git commit -m "feat(p0.2): supabase phone auth + local test OTP + send-sms hook scaffold"
```

---

### Task 2: AuthRepository

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`
- Test: `test/features/auth/auth_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/auth_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  late _MockClient client;
  late _MockAuth auth;
  setUp(() {
    client = _MockClient();
    auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
  });

  test('sendOtp calls signInWithOtp with the phone', () async {
    when(() => auth.signInWithOtp(phone: any(named: 'phone')))
        .thenAnswer((_) async {});
    await AuthRepository(client).sendOtp('+84900000001');
    verify(() => auth.signInWithOtp(phone: '+84900000001')).called(1);
  });

  test('verifyOtp calls verifyOTP with sms type', () async {
    when(() => auth.verifyOTP(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => AuthResponse(session: null, user: null));
    await AuthRepository(client).verifyOtp('+84900000001', '123456');
    verify(() => auth.verifyOTP(
        phone: '+84900000001', token: '123456', type: OtpType.sms)).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_repository_test.dart`
Expected: FAIL — `auth_repository.dart` not found.

- [ ] **Step 3: Implement AuthRepository**

Create `lib/features/auth/data/auth_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Future<void> sendOtp(String phone) => _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp(String phone, String token) =>
      _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);

  Future<void> signOut() => _client.auth.signOut();

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/auth/data/ test/features/auth/auth_repository_test.dart
git commit -m "feat(p0.2): AuthRepository (sendOtp/verifyOtp/signOut/authState)"
```

---

### Task 3: Auth providers (repository + auth-state stream)

**Files:**
- Create: `lib/features/auth/application/auth_providers.dart`
- Test: `test/features/auth/auth_providers_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/auth_providers_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  test('isSignedInProvider is false when no session', () {
    final client = _MockClient();
    final auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    expect(container.read(isSignedInProvider), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_providers_test.dart`
Expected: FAIL — `auth_providers.dart` not found.

- [ ] **Step 3: Implement providers**

Create `lib/features/auth/application/auth_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Emits on every auth change; the router listens to this to re-evaluate redirect.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);

final isSignedInProvider = Provider<bool>((ref) {
  // Re-read on each auth event.
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentSession != null;
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_providers_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/auth/application/ test/features/auth/auth_providers_test.dart
git commit -m "feat(p0.2): auth providers (repository + authState stream + isSignedIn)"
```

---

### Task 4: Auth controller (idle → codeSent → verified/error)

**Files:**
- Create: `lib/features/auth/application/auth_controller.dart`
- Test: `test/features/auth/auth_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/auth/auth_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  test('sendOtp moves phase idle -> codeSent', () async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final ctrl = container.read(authControllerProvider.notifier);
    await ctrl.sendOtp('+84900000001');
    expect(container.read(authControllerProvider).phase, AuthPhase.codeSent);
    expect(container.read(authControllerProvider).phone, '+84900000001');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_controller_test.dart`
Expected: FAIL — `auth_controller.dart` not found.

- [ ] **Step 3: Implement the controller**

Create `lib/features/auth/application/auth_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

enum AuthPhase { idle, sending, codeSent, verifying, error }

class AuthFlowState {
  const AuthFlowState({this.phase = AuthPhase.idle, this.phone, this.error});
  final AuthPhase phase;
  final String? phone;
  final String? error;

  AuthFlowState copyWith({AuthPhase? phase, String? phone, String? error}) =>
      AuthFlowState(
        phase: phase ?? this.phase,
        phone: phone ?? this.phone,
        error: error,
      );
}

class AuthController extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(phase: AuthPhase.sending, phone: phone);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      state = state.copyWith(phase: AuthPhase.codeSent, phone: phone);
    } catch (e) {
      state = state.copyWith(phase: AuthPhase.error, error: e.toString());
    }
  }

  Future<void> verifyOtp(String token) async {
    final phone = state.phone;
    if (phone == null) return;
    state = state.copyWith(phase: AuthPhase.verifying, phone: phone);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phone, token);
      state = state.copyWith(phase: AuthPhase.verified, phone: phone);
    } catch (e) {
      state = state.copyWith(phase: AuthPhase.error, error: e.toString());
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthFlowState>(AuthController.new);
```

Note: add `verified` to `AuthPhase`:
```dart
enum AuthPhase { idle, sending, codeSent, verifying, verified, error }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/auth_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/auth/application/auth_controller.dart test/features/auth/auth_controller_test.dart
git commit -m "feat(p0.2): AuthController state machine (idle/sending/codeSent/verifying/verified/error)"
```

---

### Task 5: Phone input screen (+84)

**Files:**
- Create: `lib/features/auth/presentation/phone_screen.dart`
- Test: `test/features/auth/phone_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/auth/phone_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/phone_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('entering a number and tapping send calls sendOtp', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PhoneScreen()),
    ));
    await tester.enterText(find.byType(TextField), '900000001');
    await tester.tap(find.byKey(const Key('send_otp_btn')));
    await tester.pump();
    verify(() => repo.sendOtp('+84900000001')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/phone_screen_test.dart`
Expected: FAIL — `phone_screen.dart` not found.

- [ ] **Step 3: Implement PhoneScreen**

Create `lib/features/auth/presentation/phone_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();

  String _normalize(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    return '+84$d';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixText: '+84 ', labelText: 'Số điện thoại',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('send_otp_btn'),
              onPressed: state.phase == AuthPhase.sending
                  ? null
                  : () => ref.read(authControllerProvider.notifier)
                      .sendOtp(_normalize(_ctrl.text)),
              child: const Text('Gửi mã OTP'),
            ),
            if (state.phase == AuthPhase.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error ?? 'Lỗi', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/phone_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/auth/presentation/phone_screen.dart test/features/auth/phone_screen_test.dart
git commit -m "feat(p0.2): phone input screen (+84 normalization, send OTP)"
```

---

### Task 6: OTP verify screen

**Files:**
- Create: `lib/features/auth/presentation/otp_screen.dart`
- Test: `test/features/auth/otp_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/auth/otp_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/otp_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('entering code and tapping verify calls verifyOtp', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(() => repo.verifyOtp(any(), any()))
        .thenAnswer((_) async => AuthResponse(session: null, user: null));
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).sendOtp('+84900000001');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OtpScreen()),
    ));
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.pump();
    verify(() => repo.verifyOtp('+84900000001', '123456')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/otp_screen_test.dart`
Expected: FAIL — `otp_screen.dart` not found.

- [ ] **Step 3: Implement OtpScreen**

Create `lib/features/auth/presentation/otp_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập mã OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mã đã gửi tới ${state.phone ?? ''}'),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã 6 số'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('verify_otp_btn'),
              onPressed: state.phase == AuthPhase.verifying
                  ? null
                  : () => ref.read(authControllerProvider.notifier).verifyOtp(_ctrl.text),
              child: const Text('Xác nhận'),
            ),
            if (state.phase == AuthPhase.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error ?? 'Lỗi', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/auth/otp_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/auth/presentation/otp_screen.dart test/features/auth/otp_screen_test.dart
git commit -m "feat(p0.2): OTP verify screen"
```

---

### Task 7: Router auth-redirect + auth routes

**Files:**
- Modify: `lib/app/router.dart`, `lib/app/app.dart`
- Test: `test/app/router_redirect_test.dart`

- [ ] **Step 1: Write the failing test (redirect logic as a pure function)**

Create `test/app/router_redirect_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/router.dart';

void main() {
  test('unauthenticated is sent to /auth', () {
    expect(authRedirect(signedIn: false, hasProfile: false, location: '/'), '/auth');
  });
  test('signed-in without profile goes to /onboarding', () {
    expect(authRedirect(signedIn: true, hasProfile: false, location: '/'), '/onboarding');
  });
  test('signed-in with profile on /auth goes home', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/auth'), '/');
  });
  test('signed-in with profile elsewhere is not redirected', () {
    expect(authRedirect(signedIn: true, hasProfile: true, location: '/'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/app/router_redirect_test.dart`
Expected: FAIL — `authRedirect` not defined.

- [ ] **Step 3: Implement the pure redirect + provider-based router**

Replace `lib/app/router.dart`:
```dart
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
      final hasProfile = ref.read(myProfileProvider).valueOrNull != null;
      return authRedirect(
        signedIn: signedIn, hasProfile: hasProfile, location: state.uri.path,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/auth', builder: (_, __) => const PhoneScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const _OnboardingPlaceholder()),
    ],
  );
});

/// Bridges Riverpod auth/profile changes to go_router refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(myProfileProvider, (_, __) => notifyListeners());
  }
}

/// Replaced by the real onboarding flow in P0.3.
class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Onboarding — P0.3'));
}
```

- [ ] **Step 4: Point the app at the provider router + run tests**

Replace `lib/app/app.dart` body to consume `goRouterProvider`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'router.dart';

class CungHatApp extends ConsumerWidget {
  const CungHatApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cùng Hát',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4), useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
```
Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test test/app/router_redirect_test.dart
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: redirect tests PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```
git add lib/app/router.dart lib/app/app.dart test/app/router_redirect_test.dart
git commit -m "feat(p0.2): go_router auth redirect (pure authRedirect + provider router)"
```

---

### Task 8: Auth l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/features/auth/presentation/*.dart`

- [ ] **Step 1: Add strings to both ARBs**

`app_en.arb` add: `"authTitle":"Sign in","phoneLabel":"Phone number","sendOtp":"Send OTP","otpTitle":"Enter OTP","otpLabel":"6-digit code","verify":"Confirm"`
`app_vi.arb` add: `"authTitle":"Đăng nhập","phoneLabel":"Số điện thoại","sendOtp":"Gửi mã OTP","otpTitle":"Nhập mã OTP","otpLabel":"Mã 6 số","verify":"Xác nhận"`

- [ ] **Step 2: Generate + swap hardcoded strings**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" gen-l10n`
Replace the hardcoded Vietnamese strings in `phone_screen.dart` / `otp_screen.dart` with `AppLocalizations.of(context).<key>` (import `package:flutter_gen/gen_l10n/app_localizations.dart`).

- [ ] **Step 3: Run full suite**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test` then `... analyze`
Expected: all green; `No issues found!`.

- [ ] **Step 4: Commit**

```
git add lib/l10n/ lib/features/auth/presentation/
git commit -m "feat(p0.2): localize auth screens (EN/VI)"
```

---

### Task 9: Acceptance — local OTP login round-trip

**Files:** none (verification only)

- [ ] **Step 1: Run against local stack**

Ensure `supabase start` is up. Run:
`& "C:\Users\Public\flutter\bin\flutter.bat" run -d chrome --dart-define-from-file=env/dev.json`

- [ ] **Step 2: Log in with the test number**

In the app: enter `900000001` → Send OTP → enter `123456` → Confirm.
Expected: session is created; router redirects to `/onboarding` (no profile yet → P0.3 placeholder shows).

- [ ] **Step 3: Confirm suite + clean tree**

Run: `... analyze` and `... test`; `git status`.
Expected: green; clean tree.

---

## Self-Review (completed by author)

- **Spec coverage:** phone OTP (+84) ✓ (T1–T6), provider-agnostic Send-SMS hook scaffold ✓ (T1), session + auth-state ✓ (T3), router redirect unauth/no-profile/home ✓ (T7), l10n ✓ (T8). The **18+ DOB gate** is intentionally in **P0.3** (DOB is captured during onboarding); `profiles.age_verified` already exists from P0 `0001`.
- **Placeholder scan:** the only placeholder is `_OnboardingPlaceholder` (explicitly replaced in P0.3) and the prod SMS provider `TODO` (local uses test_otp) — both intentional and labelled.
- **Type consistency:** `AuthRepository` API (`sendOtp/verifyOtp/signOut/currentSession/onAuthStateChange`) is identical across T2/T3/T4; `authRepositoryProvider`, `authControllerProvider`, `authStateProvider`, `isSignedInProvider` names consistent T3→T7; `authRedirect(signedIn,hasProfile,location)` signature identical T7 test+impl; reuses P0 `supabaseClientProvider`, `myProfileProvider`.

---

## Next: P0.3 — Onboarding (consent + 18+ DOB gate) + gamified music-taste picker (genres/artists/bài tủ from curated list).
