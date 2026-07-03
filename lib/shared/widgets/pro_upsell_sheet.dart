import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bottom sheet mời nâng cấp Pro — dùng chung cho gate ở Kèo và Đôi.
class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => ProUpsellSheet(title: title, subtitle: subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryDark,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/store');
                },
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Nâng cấp Pro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
