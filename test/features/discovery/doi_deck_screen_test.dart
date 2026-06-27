import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/doi_deck_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';

class _FakeLocationService extends Mock implements LocationService {}

void main() {
  testWidgets(
    'DoiDeckScreen uses the shared EmptyState when no candidates load',
    (tester) async {
      final locationService = _FakeLocationService();
      when(
        () => locationService.captureAndPush(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            candidatesProvider.overrideWith((ref) async => <Candidate>[]),
            locationServiceProvider.overrideWithValue(locationService),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DoiDeckScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Chưa có bạn hát quanh đây'), findsOneWidget);
    },
  );
}
