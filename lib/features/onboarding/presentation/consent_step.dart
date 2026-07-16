import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

const consentPurposes = [
  'location',
  'photos',
  'matching',
  'marketing',
  'cross_border',
];

/// Purposes a user MUST grant to complete onboarding.
const requiredConsents = {'location', 'photos', 'matching', 'cross_border'};

const _requiredConsentOrder = [
  'location',
  'photos',
  'matching',
  'cross_border',
];

List<String> missingRequiredConsents(Map<String, bool> values) => [
  for (final purpose in requiredConsents)
    if (values[purpose] != true) purpose,
];

void grantRequiredConsents(Map<String, bool> values) {
  for (final purpose in requiredConsents) {
    values[purpose] = true;
  }
}

const consentLabelsVi = {
  'location': 'Dùng vị trí để gợi ý người/kèo gần bạn',
  'photos': 'Lưu và hiển thị ảnh hồ sơ',
  'matching': 'Dùng gu nhạc để ghép người',
  'marketing': 'Nhận thông báo khuyến mãi',
  'cross_border':
      'Tôi đồng ý Chính sách bảo mật, Điều khoản và việc lưu dữ liệu tại Singapore',
};

/// Nhãn consent theo l10n (fallback map VI). Dùng chung onboarding + Cài đặt
/// để cả 2 nơi đổi ngôn ngữ nhất quán.
String consentLabel(String purpose, AppLocalizations? l10n) {
  final localized = switch (purpose) {
    'location' => l10n?.consentLocation,
    'photos' => l10n?.consentPhotos,
    'matching' => l10n?.consentMatching,
    'marketing' => l10n?.consentMarketing,
    'cross_border' => l10n?.consentCrossBorder,
    _ => null,
  };
  return localized ?? consentLabelsVi[purpose] ?? purpose;
}

class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key, required this.values, required this.onChanged});

  final Map<String, bool> values;
  final void Function(String purpose, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    String labelFor(String purpose) => consentLabel(purpose, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.onbConsentSubtitle ?? 'Bạn chọn cách Cùng Hát dùng dữ liệu',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        // P2: một chạm gộp — bật TOÀN BỘ consent (kể cả marketing; user vẫn
        // tắt lại từng cái được). Giảm ma sát đọc 5 dòng ở bước 2 funnel.
        OutlinedButton.icon(
          key: const Key('consent_all_btn'),
          onPressed: () {
            for (final purpose in consentPurposes) {
              onChanged(purpose, true);
            }
          },
          icon: const Icon(Icons.done_all_rounded),
          label: Text(l10n?.onbConsentAll ?? 'Đồng ý tất cả'),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final purpose in _requiredConsentOrder) ...[
          _RequiredConsentRow(
            key: Key('consent_$purpose'),
            icon: _iconFor(purpose),
            label: labelFor(purpose),
            requiredLabel: l10n?.onbRequired ?? 'Bắt buộc',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: const [AppShadows.hard],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              key: const Key('consent_marketing'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              secondary: const _ConsentIcon(icon: Icons.notifications_outlined),
              title: Text(labelFor('marketing')),
              value: values['marketing'] ?? false,
              onChanged: (value) => onChanged('marketing', value),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () => context.push('/legal/privacy'),
                child: Text(l10n?.privacyTitle ?? 'Chính sách bảo mật'),
              ),
              TextButton(
                onPressed: () => context.push('/legal/tos'),
                child: Text(l10n?.tosTitle ?? 'Điều khoản'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(String purpose) => switch (purpose) {
  'location' => Icons.location_on_outlined,
  'photos' => Icons.photo_camera_back_outlined,
  'matching' => Icons.music_note_outlined,
  'cross_border' => Icons.shield_outlined,
  _ => Icons.info_outline,
};

class _RequiredConsentRow extends StatelessWidget {
  const _RequiredConsentRow({
    super.key,
    required this.icon,
    required this.label,
    required this.requiredLabel,
  });

  final IconData icon;
  final String label;
  final String requiredLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: const [AppShadows.hard],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ConsentIcon(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.secondaryDark, width: 2),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              requiredLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentIcon extends StatelessWidget {
  const _ConsentIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.tertiaryTint,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Icon(icon, color: AppColors.ink, size: 28),
    );
  }
}
