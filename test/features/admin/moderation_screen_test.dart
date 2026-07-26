import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/admin/application/admin_providers.dart';
import 'package:cung_hat/features/admin/data/moderation_repository.dart';
import 'package:cung_hat/features/admin/presentation/moderation_screen.dart';

void main() {
  // [SWEEP 2026-07-26] Do tren may: bao cao moi KHONG hien khi mo lai man —
  // openReportsProvider la FutureProvider thuong nen replay ket qua rong da
  // cache. Kiem duyet vien phai kill app moi thay report moi.
  test(
    'openReportsProvider autoDispose: het nguoi xem -> lan sau fetch tuoi',
    () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          openReportsProvider.overrideWith((ref) async {
            calls++;
            return <Report>[];
          }),
        ],
      );
      addTearDown(container.dispose);

      // Mo man lan 1.
      var sub = container.listen(openReportsProvider, (_, _) {});
      await container.read(openReportsProvider.future);
      expect(calls, 1);

      // Roi man -> het listener -> autoDispose huy state.
      sub.close();
      await Future<void>.delayed(Duration.zero);

      // Mo lai: PHAI goi repo lan nua thay vi replay danh sach cu.
      sub = container.listen(openReportsProvider, (_, _) {});
      await container.read(openReportsProvider.future);
      expect(
        calls,
        2,
        reason: 'mo lai phai fetch tuoi, khong replay danh sach da cache',
      );
      sub.close();
    },
  );

  testWidgets('keo xuong -> fetch lai bao cao', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openReportsProvider.overrideWith((ref) async {
            calls++;
            return [
              Report(
                id: 'r1',
                targetType: 'profile',
                targetId: 'u9',
                reason: 'Quấy rối',
                status: 'open',
              ),
            ];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ModerationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
