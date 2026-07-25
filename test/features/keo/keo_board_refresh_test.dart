import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';

/// [DEBT] Toan app tung khong co keo-de-lam-moi. Test nay chot: keo xuong
/// tren board -> openKeosProvider fetch lai.
class _CountingKeoRepository implements KeoRepository {
  int listCalls = 0;

  @override
  Future<List<Keo>> listOpenKeos({int limit = 30}) async {
    listCalls++;
    return const [
      Keo(
        id: 'k1',
        title: 'Kèo hát demo',
        areaLabel: 'Cầu Giấy',
        status: 'open',
        sizeTarget: 4,
        slotsFilled: 2,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('keo xuong tren board -> danh sach keo duoc fetch lai', (
    tester,
  ) async {
    final repo = _CountingKeoRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keoRepositoryProvider.overrideWithValue(repo),
          entitlementsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KeoBoardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.listCalls, 1);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.listCalls, 2);
  });
}
