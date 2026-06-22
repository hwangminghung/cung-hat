import 'package:flutter/material.dart';
import 'package:cung_hat/l10n/app_localizations.dart';

const consentPurposes = ['location', 'photos', 'matching', 'marketing', 'cross_border'];

/// Purposes a user MUST grant to complete onboarding (core function + PDPL data residency).
const requiredConsents = {'matching', 'cross_border'};

/// Returns the required purposes that are NOT granted in [values].
List<String> missingRequiredConsents(Map<String, bool> values) =>
    [for (final p in requiredConsents) if (values[p] != true) p];

const consentLabelsVi = {
  'location': 'Dùng vị trí để gợi ý người/kèo gần bạn',
  'photos': 'Lưu & hiển thị ảnh hồ sơ (tùy chọn)',
  'matching': 'Dùng gu nhạc để ghép người',
  'marketing': 'Nhận thông báo khuyến mãi',
  'cross_border': 'Dữ liệu lưu tại Singapore (chuyển xuyên biên giới)',
};

class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key, required this.values, required this.onChanged});
  final Map<String, bool> values;
  final void Function(String purpose, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    String labelFor(String p) {
      final localized = switch (p) {
        'location' => l10n?.consentLocation,
        'photos' => l10n?.consentPhotos,
        'matching' => l10n?.consentMatching,
        'marketing' => l10n?.consentMarketing,
        'cross_border' => l10n?.consentCrossBorder,
        _ => null,
      };
      return localized ?? consentLabelsVi[p] ?? p;
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final p in values.keys)
          SwitchListTile(
            key: Key('consent_$p'),
            title: Text(labelFor(p)),
            value: values[p] ?? false,
            onChanged: (v) => onChanged(p, v),
          ),
      ],
    );
  }
}
