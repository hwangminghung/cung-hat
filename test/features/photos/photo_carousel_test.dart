import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/features/photos/application/photo_providers.dart';
import 'package:cung_hat/features/photos/presentation/photo_carousel.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String userId,
  required List<String> urls,
  required String monogram,
  bool swipeable = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        signedUrlsProvider(userId).overrideWith((ref) async => urls),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PhotoCarousel(
            userId: userId,
            monogram: monogram,
            swipeable: swipeable,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('0 ảnh → fallback monogram, không có PageView', (tester) async {
    await _pump(tester, userId: 'u1', urls: const [], monogram: 'L');
    await tester.pump();

    expect(find.text('L'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('2 ảnh → PageView + 2 chấm', (tester) async {
    await _pump(
      tester,
      userId: 'u2',
      urls: const ['https://a', 'https://b'],
      monogram: 'M',
      swipeable: true,
    );
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(PhotoDot), findsNWidgets(2));
  });
}
