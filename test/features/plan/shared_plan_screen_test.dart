import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/presentation/shared_plan_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/skeleton.dart';

/// [UI-AUDIT] Shared Plan đồng khuôn Shared Kèo: skeleton / lỗi-mạng-có-retry
/// / không-tồn-tại là BA trạng thái khác nhau (trước đây lỗi mạng cũng hiện
/// "Không tìm thấy kế hoạch" — nói dối user đang offline).
void main() {
  Widget host(FutureOr<Map<String, dynamic>> Function() resolver) {
    return ProviderScope(
      overrides: [
        resolveShareProvider('tok').overrideWith((ref) async => resolver()),
      ],
      child: const MaterialApp(home: SharedPlanScreen(token: 'tok')),
    );
  }

  testWidgets('đang tải → skeleton, không phải spinner trần', (tester) async {
    final gate = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(host(() => gate.future));
    await tester.pump();

    expect(find.byType(SkeletonTile), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    gate.complete({'venue_name': null});
    await tester.pumpAndSettle();
  });

  testWidgets('lỗi mạng → EmptyState + nút Thử lại refetch provider', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(() {
        calls++;
        // StateError (Error, không phải Exception) để Riverpod không
        // auto-retry — cùng khuôn router_redirect_test.
        throw StateError('offline');
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được kế hoạch'), findsOneWidget);
    expect(find.text('Không tìm thấy kế hoạch'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('server trả null thật → "Không tìm thấy kế hoạch"', (
    tester,
  ) async {
    await tester.pumpWidget(host(() => {'venue_name': null}));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Không tìm thấy kế hoạch'), findsOneWidget);
  });

  testWidgets('dữ liệu thật → hiện tên quán', (tester) async {
    await tester.pumpWidget(
      host(
        () => {
          'venue_name': 'Karaoke ABC',
          'address': '1 Cầu Giấy',
          'scheduled_at': '2026-08-02T12:00:00Z',
          'expired': false,
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Karaoke ABC'), findsOneWidget);
  });
}
