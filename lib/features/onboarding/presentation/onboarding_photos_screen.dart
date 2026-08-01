import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../photos/presentation/photo_manager_sheet.dart';

/// P1-6: bước ảnh OPTIONAL chạy SAU khi onboarding submit xong (profile đã
/// tồn tại nên upload ảnh + consent 'photos' — bắt buộc ở bước 2 — đều sẵn
/// sàng). Route /onboarding/photos được authRedirect cho ở lại (chỉ match
/// đúng chuỗi '/onboarding'). Skip được: cả Xong lẫn Để sau đều về home.
class OnboardingPhotosScreen extends StatelessWidget {
  const OnboardingPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n?.onbPhotosTitle ?? 'Thêm ảnh')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Text(
                  l10n?.onbPhotosSubOptional ??
                      'Không bắt buộc — bạn có thể bổ sung hoặc đổi ảnh bất cứ lúc nào trong Hồ sơ.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const PhotoManagerSheet(showHandle: false),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                TextButton(
                  key: const Key('onb_photos_skip'),
                  onPressed: () => context.go('/'),
                  child: Text(l10n?.onbPhotosSkip ?? 'Để sau'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GradientButton(
                    key: const Key('onb_photos_done'),
                    onPressed: () => context.go('/'),
                    child: Text(l10n?.onbPhotosDone ?? 'Xong'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
