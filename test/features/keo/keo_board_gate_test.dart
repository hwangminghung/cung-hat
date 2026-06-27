import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_board_screen.dart';

/// Minimal fake repo: the board only needs an empty open-keos list so it
/// renders its EmptyState. Everything else is a no-op.
class _FakeKeoRepository implements KeoRepository {
  @override
  Future<List<Keo>> listOpenKeos({int limit = 30}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderScope _wrap(Widget child, {required Set<String> entitlements}) {
  return ProviderScope(
    overrides: [
      keoRepositoryProvider.overrideWithValue(_FakeKeoRepository()),
      entitlementsProvider.overrideWith((ref) async => entitlements),
    ],
    child: child,
  );
}

void main() {
  testWidgets('FREE user: tapping Tạo kèo shows the upgrade sheet', (tester) async {
    await tester.pumpWidget(_wrap(
      MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
      entitlements: const <String>{},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo kèo là tính năng Pro'), findsOneWidget);
    expect(find.text('Nâng cấp Pro'), findsOneWidget);
  });

  testWidgets('PRO user: tapping Tạo kèo does NOT show the upgrade sheet',
      (tester) async {
    // Pro path calls context.push('/keo/create'); wire a tiny router so the
    // tap doesn't crash, then assert the upgrade sheet is absent.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const KeoBoardScreen()),
        GoRoute(
            path: '/keo/create',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('create-stub')))),
        GoRoute(
            path: '/store',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('store-stub')))),
      ],
    );

    await tester.pumpWidget(_wrap(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      entitlements: const <String>{'pro'},
    ));
    await tester.pumpAndSettle();

    // The FAB reads isProProvider, which depends on the async entitlements
    // future. Nothing in this isolated screen keeps that future alive, so warm
    // it (as a parent shell would in the real app) before tapping.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(KeoBoardScreen)));
    await container.read(entitlementsProvider.future);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo kèo'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo kèo là tính năng Pro'), findsNothing);
    expect(find.text('create-stub'), findsOneWidget);
  });
}
