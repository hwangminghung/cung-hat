import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/wave_divider.dart';

class ProfileStep extends StatelessWidget {
  const ProfileStep({
    super.key,
    required this.nameController,
    required this.bioController,
    required this.brand,
  });

  final TextEditingController nameController;
  final TextEditingController bioController;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.onbStepProfile ?? 'Thiết lập hồ sơ',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ProfilePreview(
          key: const Key('onb_profile_preview'),
          controller: nameController,
          brand: brand,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n?.onbProfileQuestion ?? 'Bạn muốn mọi người gọi mình là gì?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('onb_name'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n?.onbNameLabel ?? 'Tên hiển thị',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('onb_bio'),
          controller: bioController,
          minLines: 3,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n?.onbBioLabel ?? 'Giới thiệu',
          ),
        ),
      ],
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    super.key,
    required this.controller,
    required this.brand,
  });

  final TextEditingController controller;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [AppShadows.hard],
      ),
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final trimmed = value.text.trim();
                final monogram = trimmed.isEmpty
                    ? 'M'
                    : String.fromCharCode(trimmed.runes.first).toUpperCase();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      monogram,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.ink,
                        fontSize: 82,
                        height: 1,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.xl,
                      top: AppSpacing.xs,
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.secondaryDark,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: WaveDivider(
                  height: AppSpacing.xxl,
                  color: AppColors.ink,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.language, color: AppColors.ink, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                brand,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
