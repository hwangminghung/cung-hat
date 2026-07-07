import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/presentation/filter_sheet.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  Widget host({
    required DiscoveryRepository repo,
    required FutureOr<({bool autoExpand, int radiusKm})> Function(Ref)
        prefs,
  }) {
    return ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
        discoveryPrefsProvider.overrideWith(prefs),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: FilterSheet()),
      ),
    );
  }

  group('FilterSheet', () {
    testWidgets('render slider ở giá trị server (radiusKm=70)',
        (tester) async {
      final repo = _MockDiscoveryRepository();
      await tester.pumpWidget(host(
        repo: repo,
        prefs: (ref) async => (autoExpand: false, radiusKm: 70),
      ));
      await tester.pumpAndSettle();

      expect(find.text('70 km'), findsOneWidget);
      final slider =
          tester.widget<Slider>(find.byKey(const Key('filter_radius_slider')));
      expect(slider.value, 70.0);

      final switchTile = tester.widget<SwitchListTile>(
          find.byKey(const Key('filter_auto_expand_switch')));
      expect(switchTile.value, isFalse);
    });

    testWidgets('kéo slider → label cập nhật theo giá trị mới',
        (tester) async {
      final repo = _MockDiscoveryRepository();
      await tester.pumpWidget(host(
        repo: repo,
        prefs: (ref) async => (autoExpand: false, radiusKm: 50),
      ));
      await tester.pumpAndSettle();

      expect(find.text('50 km'), findsOneWidget);

      // Kéo slider hết cỡ sang phải → giá trị max = 100.
      await tester.drag(
          find.byKey(const Key('filter_radius_slider')), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('100 km'), findsOneWidget);
    });

    testWidgets(
        'bấm Áp dụng → gọi setDiscoveryRadius + setAutoExpand, invalidate + null hoá override phiên',
        (tester) async {
      final repo = _MockDiscoveryRepository();
      when(() => repo.setDiscoveryRadius(any())).thenAnswer((_) async {});
      when(() => repo.setAutoExpand(any())).thenAnswer((_) async {});

      final container = ProviderContainer(overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
        discoveryPrefsProvider.overrideWith(
            (ref) async => (autoExpand: false, radiusKm: 50)),
        // Override phiên đang có giá trị 100 (one-shot mở rộng cũ) — Áp dụng
        // phải null hoá lại nó.
        deckRadiusProvider.overrideWith((ref) => 100),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: FilterSheet()),
        ),
      ));
      await tester.pumpAndSettle();

      // Kéo slider sang phải để đổi giá trị trước khi lưu (80km).
      await tester.drag(
          find.byKey(const Key('filter_radius_slider')), const Offset(150, 0));
      await tester.pumpAndSettle();
      final newKm = tester
          .widget<Slider>(find.byKey(const Key('filter_radius_slider')))
          .value
          .round();

      await tester.tap(find.byKey(const Key('filter_save_btn')));
      await tester.pumpAndSettle();

      verify(() => repo.setDiscoveryRadius(newKm)).called(1);
      verify(() => repo.setAutoExpand(false)).called(1);
      expect(container.read(deckRadiusProvider), isNull);
    });

    testWidgets('bấm Áp dụng lỗi → SnackBar báo lỗi, không crash',
        (tester) async {
      final repo = _MockDiscoveryRepository();
      when(() => repo.setDiscoveryRadius(any()))
          .thenAnswer((_) async => throw Exception('offline'));
      when(() => repo.setAutoExpand(any())).thenAnswer((_) async {});

      await tester.pumpWidget(host(
        repo: repo,
        prefs: (ref) async => (autoExpand: false, radiusKm: 50),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_save_btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Không lưu được, thử lại.'), findsOneWidget);
      // Sheet vẫn còn (chưa pop) khi lưu lỗi.
      expect(find.byType(FilterSheet), findsOneWidget);
    });

    testWidgets('trong lúc prefs chưa tải xong → nút Áp dụng bị khoá',
        (tester) async {
      final repo = _MockDiscoveryRepository();
      final completer = Completer<({bool autoExpand, int radiusKm})>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repo),
          discoveryPrefsProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: FilterSheet()),
        ),
      ));
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('filter_save_btn')))
            .onPressed,
        isNull,
      );

      completer.complete((autoExpand: false, radiusKm: 50));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('filter_save_btn')))
            .onPressed,
        isNotNull,
      );
    });
  });
}
