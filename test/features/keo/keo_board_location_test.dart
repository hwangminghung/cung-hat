import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';

/// Đếm số lần board fetch để chứng minh retry có invalidate openKeosProvider.
class _CountingKeoRepository implements KeoRepository {
  int listCalls = 0;

  @override
  Future<List<Keo>> listOpenKeos({int limit = 30}) async {
    listCalls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLocationService extends Mock implements LocationService {}

ProviderScope _wrap({
  required _CountingKeoRepository repo,
  required LocationService locationService,
  LocationCaptureStatus? status,
}) {
  return ProviderScope(
    overrides: [
      keoRepositoryProvider.overrideWithValue(repo),
      locationServiceProvider.overrideWithValue(locationService),
      entitlementsProvider.overrideWith((ref) async => <String>{}),
      locationStatusProvider.overrideWith((ref) => status),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
  );
}

void main() {
  testWidgets(
    'board rỗng + chưa cấp quyền vị trí → error state đúng nguyên nhân (P0-1)',
    (tester) async {
      final repo = _CountingKeoRepository();
      await tester.pumpWidget(
        _wrap(
          repo: repo,
          locationService: _MockLocationService(),
          status: LocationCaptureStatus.permissionDenied,
        ),
      );
      await tester.pumpAndSettle();

      // Không được đổ lỗi "chưa có kèo" khi thật ra là thiếu quyền vị trí.
      expect(find.text('Cần quyền vị trí'), findsOneWidget);
      expect(find.text('Mở cài đặt'), findsOneWidget);
      expect(find.text('Chưa có kèo quanh đây'), findsNothing);
    },
  );

  testWidgets(
    'board rỗng + vị trí OK (hoặc chưa thử) → empty state thường',
    (tester) async {
      final repo = _CountingKeoRepository();
      await tester.pumpWidget(
        _wrap(
          repo: repo,
          locationService: _MockLocationService(),
          status: LocationCaptureStatus.success,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có kèo quanh đây'), findsOneWidget);
      expect(find.text('Cần quyền vị trí'), findsNothing);
    },
  );

  testWidgets(
    'Thử lại trên board thành công → fetch lại kèo + về empty state thường',
    (tester) async {
      final repo = _CountingKeoRepository();
      final locationService = _MockLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => LocationCaptureStatus.success);

      await tester.pumpWidget(
        _wrap(
          repo: repo,
          locationService: locationService,
          status: LocationCaptureStatus.noFix,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không lấy được vị trí'), findsOneWidget);
      final callsBeforeRetry = repo.listCalls;

      // Nút nằm cuối EmptyState trong ListView — cuộn vào tầm nhìn trước,
      // nếu không tap sẽ trượt (off-screen) và verify 0 call.
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      verify(() => locationService.captureAndPush()).called(1);
      expect(repo.listCalls, greaterThan(callsBeforeRetry));
      expect(find.text('Chưa có kèo quanh đây'), findsOneWidget);
      expect(find.text('Không lấy được vị trí'), findsNothing);
    },
  );
}
