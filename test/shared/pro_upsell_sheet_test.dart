import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cung_hat/shared/widgets/pro_upsell_sheet.dart';

void main() {
  Widget host(ProUpsellVariant variant) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Builder(
            builder: (context) => TextButton(
              onPressed: () => ProUpsellSheet.show(context, variant: variant),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/store',
          builder: (context, state) => const Text('STORE'),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  for (final (variant, headline) in [
    (ProUpsellVariant.boost, 'Tăng hiển thị hồ sơ của bạn'),
    (ProUpsellVariant.rewind, 'Rút lại lượt vuốt'),
    (ProUpsellVariant.seeLikes, 'Xem ai đã thích bạn'),
    (ProUpsellVariant.keoCreate, 'Tự tạo kèo của riêng bạn'),
    (ProUpsellVariant.keoJoinLimit, 'Tham gia nhiều kèo cùng lúc'),
    (ProUpsellVariant.likeQuota, 'Hết lượt thích hôm nay'),
    (ProUpsellVariant.superQuota, 'Hết lượt Siêu thích hôm nay'),
  ]) {
    testWidgets('variant $variant: đúng headline, không giá, CTA về store', (
      tester,
    ) async {
      await tester.pumpWidget(host(variant));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(headline), findsOneWidget);
      // Không hardcode giá — vùng pricing thuộc nhánh Codex.
      expect(find.textContaining('₫'), findsNothing);
      expect(find.textContaining('.000'), findsNothing);
      expect(find.byKey(const Key('upsell_cta_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('upsell_cta_btn')));
      await tester.pumpAndSettle();
      expect(find.text('STORE'), findsOneWidget);
    });
  }
}
