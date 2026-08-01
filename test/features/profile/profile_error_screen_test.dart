import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/presentation/profile_error_screen.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  // [AUDIT P1-4] Lỗi tải hồ sơ trước đây đưa user CŨ về màn tạo hồ sơ. Màn
  // này là đường thoát đúng: nói rõ là lỗi tải, cho thử lại, và cho đăng xuất
  // để không kẹt vĩnh viễn nếu tài khoản đó luôn lỗi.
  testWidgets('hiện lỗi tải hồ sơ kèm nút thử lại', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith(
            (ref) async => throw StateError('net'),
          ),
        ],
        child: const MaterialApp(home: ProfileErrorScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Không tải được hồ sơ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    // KHÔNG được mời user tạo lại hồ sơ — hồ sơ của họ vẫn còn trên server.
    expect(find.textContaining('Tạo hồ sơ'), findsNothing);
  });

  testWidgets('bấm Thử lại → tải lại hồ sơ', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith((ref) async {
            loads++;
            throw StateError('net');
          }),
        ],
        child: const MaterialApp(home: ProfileErrorScreen()),
      ),
    );
    await tester.pump();
    expect(loads, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(loads, 2);
  });

  testWidgets('bấm Đăng xuất → thoát tài khoản (không kẹt vĩnh viễn)', (
    tester,
  ) async {
    final auth = _MockAuth();
    when(() => auth.signOut()).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          myProfileProvider.overrideWith(
            (ref) async => throw StateError('net'),
          ),
        ],
        child: const MaterialApp(home: ProfileErrorScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Đăng xuất'));
    await tester.pump();

    verify(() => auth.signOut()).called(1);
  });

  // Rời màn này khi tải lại thành công là việc của router
  // (authRedirect: ProfileGate.present + /profile-error → '/'), đã có test
  // riêng trong test/app/router_redirect_test.dart.
}
