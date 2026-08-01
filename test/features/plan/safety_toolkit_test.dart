import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/safety_toolkit.dart';

class _MockRepo extends Mock implements PlanRepository {}

void main() {
  testWidgets('tapping "Tôi đã tới" calls checkInArrived', (tester) async {
    final repo = _MockRepo();
    when(() => repo.checkInArrived('p1')).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: SafetyToolkit(planId: 'p1')),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('checkin_btn')));
    await tester.pump();
    verify(() => repo.checkInArrived('p1')).called(1);
  });

  // [UI-AUDIT] "Chia sẻ cho bạn bè" từng xuống 3 dòng ở 360dp — hàng action
  // phụ giờ dùng label ngắn, mỗi nhãn phải nằm gọn 1 dòng kể cả textScale 1.4.
  testWidgets('label action phụ 1 dòng @360dp ×1.4', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = _MockRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: Scaffold(body: SafetyToolkit(planId: 'p1')),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final label in ['Chia sẻ', 'Tôi đã tới']) {
      final size = tester.getSize(find.text(label));
      // 1 dòng ở scale 1.4 với labelLarge 16px ≈ dưới 40px; 3 dòng thì vượt xa.
      expect(
        size.height,
        lessThan(45),
        reason: '"$label" cao ${size.height} — có vẻ đang wrap nhiều dòng',
      );
    }
  });
}
