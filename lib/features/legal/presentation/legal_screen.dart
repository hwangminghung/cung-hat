import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Văn bản pháp lý bundled. Nội dung markdown CHỈ có bản tiếng Việt (bản
/// dịch pháp lý cần luật sư review — ngoài scope l10n UI); title theo l10n.
enum LegalDoc { privacy, tos }

/// Renders a bundled markdown legal document.
///
/// [SWEEP 2026-07-26] Trước đây dùng `SelectableText(raw)` nên user đọc chính
/// sách bảo mật thấy nguyên `# Chính sách bảo mật`, `**Cùng Hát**`,
/// `## 1. Đơn vị kiểm soát dữ liệu`. Đây là màn formal nhất của app và cũng
/// là thứ reviewer store mở ra đọc.
///
/// Không thêm dependency markdown: hai file trong `assets/legal/` là của
/// chính mình và chỉ dùng đúng 3 cú pháp — `#`/`##` heading, `- ` bullet,
/// `**bold**`. [_parseLegalMarkdown] xử lý đúng tập đó; cú pháp lạ (link,
/// ảnh, code) sẽ rơi về đoạn văn thường thay vì vỡ.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final assetPath = switch (doc) {
      LegalDoc.privacy => 'assets/legal/privacy_vi.md',
      LegalDoc.tos => 'assets/legal/tos_vi.md',
    };
    final title = switch (doc) {
      LegalDoc.privacy => l10n?.privacyTitle ?? 'Chính sách bảo mật',
      LegalDoc.tos => l10n?.tosTitle ?? 'Điều khoản sử dụng',
    };
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: _parseLegalMarkdown(context, snapshot.data!),
            ),
          ),
        );
      },
    );
  }
}

/// Chuyển markdown pháp lý thành widget. Tập cú pháp hỗ trợ: `#`/`##`/`###`
/// heading, `- ` bullet, `**bold**` inline. Dòng khác = đoạn văn thường.
List<Widget> _parseLegalMarkdown(BuildContext context, String source) {
  final text = Theme.of(context).textTheme;
  final out = <Widget>[];

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) {
      out.add(const SizedBox(height: AppSpacing.md));
      continue;
    }

    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      final level = heading.group(1)!.length;
      final style = switch (level) {
        1 => text.headlineSmall,
        2 => text.titleLarge,
        _ => text.titleMedium,
      };
      out.add(
        Padding(
          padding: EdgeInsets.only(
            top: level == 1 ? 0 : AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text.rich(
            _inlineSpans(heading.group(2)!, style),
            style: style,
          ),
        ),
      );
      continue;
    }

    if (line.trimLeft().startsWith('- ')) {
      final body = line.trimLeft().substring(2);
      out.add(
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: text.bodyMedium),
              Expanded(
                child: Text.rich(
                  _inlineSpans(body, text.bodyMedium),
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
      continue;
    }

    out.add(
      Text.rich(_inlineSpans(line, text.bodyMedium), style: text.bodyMedium),
    );
  }
  return out;
}

/// Tách `**bold**` thành span. Số cặp `**` lẻ (markdown hỏng) thì phần đuôi
/// giữ nguyên chữ thường — không bao giờ in lại dấu `*` ra màn hình.
InlineSpan _inlineSpans(String line, TextStyle? base) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var index = 0;
  for (final m in pattern.allMatches(line)) {
    if (m.start > index) {
      spans.add(TextSpan(text: line.substring(index, m.start)));
    }
    spans.add(
      TextSpan(
        text: m.group(1),
        style: (base ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    index = m.end;
  }
  if (index < line.length) {
    // Bỏ mọi dấu ** còn sót (cặp lẻ) thay vì hiện ra cho user.
    spans.add(TextSpan(text: line.substring(index).replaceAll('**', '')));
  }
  return TextSpan(children: spans);
}
