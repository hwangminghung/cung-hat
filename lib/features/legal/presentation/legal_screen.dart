import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Văn bản pháp lý bundled. Nội dung markdown CHỈ có bản tiếng Việt (bản
/// dịch pháp lý cần luật sư review — ngoài scope l10n UI); title theo l10n.
enum LegalDoc { privacy, tos }

/// Renders a bundled markdown legal document as plain selectable text.
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(snapshot.data!),
          ),
        );
      },
    );
  }
}
