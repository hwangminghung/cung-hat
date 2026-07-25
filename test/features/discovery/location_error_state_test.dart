import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/presentation/location_error_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('permissionDenied → tiêu đề quyền + Mở cài đặt + Thử lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LocationErrorState(
          status: LocationCaptureStatus.permissionDenied,
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cần quyền vị trí'), findsOneWidget);
    expect(find.text('Mở cài đặt'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('serviceDisabled → tiêu đề định vị tắt + Mở cài đặt + Thử lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LocationErrorState(
          status: LocationCaptureStatus.serviceDisabled,
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Định vị đang tắt'), findsOneWidget);
    expect(find.text('Mở cài đặt'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('noFix → chỉ có Thử lại, không có Mở cài đặt', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LocationErrorState(
          status: LocationCaptureStatus.noFix,
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không lấy được vị trí'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Mở cài đặt'), findsNothing);
  });

  testWidgets('pushFailed → tiêu đề không gửi được vị trí + Thử lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LocationErrorState(
          status: LocationCaptureStatus.pushFailed,
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không gửi được vị trí'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Mở cài đặt'), findsNothing);
  });

  testWidgets('bấm Thử lại → onRetry; bấm Mở cài đặt → onOpenSettings', (
    tester,
  ) async {
    var retries = 0;
    var settingsOpens = 0;
    await tester.pumpWidget(
      _wrap(
        LocationErrorState(
          status: LocationCaptureStatus.permissionDenied,
          onRetry: () => retries++,
          onOpenSettings: () => settingsOpens++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.tap(find.text('Mở cài đặt'));
    await tester.pump();

    expect(retries, 1);
    expect(settingsOpens, 1);
  });
}
