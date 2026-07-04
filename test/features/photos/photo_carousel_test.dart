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
  BorderRadius? radius,
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
            radius: radius,
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

  // Regression guard for BUG-2: swiping to the 2nd page must load the 2nd,
  // DISTINCT url — not fall back to the 1st (or to the monogram). The old test
  // only counted PageView + dots, so a pager that fed every page urls[0] (or
  // mis-indexed page 2) would have passed while the real 2nd photo never
  // rendered. We assert on the NetworkImage each built page actually carries.
  testWidgets('swipe sang ảnh #2 → Image.network dùng đúng url thứ 2',
      (tester) async {
    await _pump(
      tester,
      userId: 'u2b',
      urls: const ['https://photo-0', 'https://photo-1'],
      monogram: 'M',
      swipeable: true,
    );
    await tester.pump();

    String urlOfVisibleImage() {
      final image = tester.widget<Image>(find.byType(Image));
      return (image.image as NetworkImage).url;
    }

    // Page 1 shows the 1st url.
    expect(urlOfVisibleImage(), 'https://photo-0');

    // Swipe to page 2 and let the PageView settle.
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Page 2 must be built from the 2nd, distinct url.
    expect(urlOfVisibleImage(), 'https://photo-1');
  });

  testWidgets('0 ảnh + radius → fallback vẫn bo góc (ClipRRect)',
      (tester) async {
    await _pump(
      tester,
      userId: 'u3',
      urls: const [],
      monogram: 'N',
      radius: BorderRadius.circular(24),
    );
    await tester.pump();

    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
  });
}
