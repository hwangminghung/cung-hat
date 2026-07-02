import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cung_hat/l10n/app_localizations.dart';

const consentPurposes = [
  'location',
  'photos',
  'matching',
  'marketing',
  'cross_border',
];

/// Purposes a user MUST grant to complete onboarding.
const requiredConsents = {'matching', 'cross_border'};

List<String> missingRequiredConsents(Map<String, bool> values) => [
  for (final purpose in requiredConsents)
    if (values[purpose] != true) purpose,
];

const consentLabelsVi = {
  'location': 'Dùng vị trí để gợi ý người/kèo gần bạn',
  'photos': 'Lưu và hiển thị ảnh hồ sơ',
  'matching': 'Dùng gu nhạc để ghép người',
  'marketing': 'Nhận thông báo khuyến mãi',
  'cross_border':
      'Tôi đồng ý Chính sách bảo mật, Điều khoản và việc lưu dữ liệu tại Singapore',
};

class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key, required this.values, required this.onChanged});

  final Map<String, bool> values;
  final void Function(String purpose, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    String labelFor(String purpose) {
      if (purpose == 'cross_border') return consentLabelsVi[purpose]!;
      final localized = switch (purpose) {
        'location' => l10n?.consentLocation,
        'photos' => l10n?.consentPhotos,
        'matching' => l10n?.consentMatching,
        'marketing' => l10n?.consentMarketing,
        _ => null,
      };
      return localized ?? consentLabelsVi[purpose] ?? purpose;
    }

    String subtitleFor(String purpose) {
      if (requiredConsents.contains(purpose)) {
        return 'Bắt buộc để tiếp tục';
      }
      return 'Tùy chọn, có thể đổi sau trong Cài đặt';
    }

    // Plain Column: this widget lives inside the Stepper's own scrollable.
    // A nested vertical ListView here becomes the "primary" scroll view and
    // swallows every drag over the tiles, so the page can't be scrolled and
    // the continue button below stays unreachable on small screens.
    return Column(
      children: [
        for (final purpose in values.keys)
          CheckboxListTile(
            key: Key('consent_$purpose'),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(labelFor(purpose)),
            subtitle: Text(subtitleFor(purpose)),
            value: values[purpose] ?? false,
            onChanged: (value) => onChanged(purpose, value ?? false),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => context.push('/legal/privacy'),
                child: const Text('Chính sách bảo mật'),
              ),
              TextButton(
                onPressed: () => context.push('/legal/tos'),
                child: const Text('Điều khoản'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
