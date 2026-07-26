import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/features/legal/presentation/legal_screen.dart';

/// Gom chu ĐANG HIEN THI tu ca Text lan SelectableText — chi quet mot loai
/// thi test pass gia khi man doi widget.
String _renderedText(WidgetTester tester) {
  final parts = <String>[
    for (final t in tester.widgetList<Text>(find.byType(Text)))
      t.data ?? t.textSpan?.toPlainText() ?? '',
    for (final t in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    ))
      t.data ?? t.textSpan?.toPlainText() ?? '',
  ];
  return parts.join('\n');
}

void main() {
  // [SWEEP 2026-07-26] Man Phap ly render markdown THO: user doc chinh sach
  // bao mat thay '# Chính sách bảo mật', '**Cùng Hát**', '## 1. Đơn vị...'.
  // Day la man formal nhat cua app va la thu reviewer store doc.
  testWidgets('privacy: khong con ky tu markdown tho tren man hinh', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(doc: LegalDoc.privacy)),
    );
    await tester.pumpAndSettle();

    // Gom toan bo text dang hien thi.
    final rendered = _renderedText(tester);

    expect(rendered, isNot(contains('**')), reason: 'con dau bold tho');
    expect(
      rendered.split('\n').where((l) => l.trimLeft().startsWith('#')),
      isEmpty,
      reason: 'con dau heading tho',
    );
    // Noi dung that van phai co mat.
    expect(rendered, contains('Nghị định 13/2023'));
    expect(rendered, contains('Singapore'));

    // Co phan cap thi giac: heading va doan van khong duoc cung mot co chu.
    // (Do o day thay vi test rieng — man nay dung SelectionArea nen pump
    // nhieu lan trong cung file lam settle khong ve.)
    final sizes = <double>{
      for (final t in tester.widgetList<Text>(
        find.descendant(of: find.byType(ListView), matching: find.byType(Text)),
      ))
        if (t.style?.fontSize != null) t.style!.fontSize!,
    };
    expect(
      sizes.length,
      greaterThan(1),
      reason: 'chi mot co chu => heading khong khac doan van, mat phan cap',
    );
  });

  testWidgets('tos: cung khong con markdown tho', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalScreen(doc: LegalDoc.tos)),
    );
    await tester.pumpAndSettle();

    final rendered = _renderedText(tester);
    expect(rendered, isNot(contains('**')));
    expect(
      rendered.split('\n').where((l) => l.trimLeft().startsWith('#')),
      isEmpty,
    );
  });
}
