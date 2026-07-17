import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'wave_divider.dart';

/// Quy tắc header CHUNG cho 4 tab (UI review 2026-07-16): cùng padding,
/// tiêu đề căn trái, action 44×44 căn phải, wave divider đóng khối. Mỗi tab
/// giữ cá tính qua tiêu đề/subtitle/action riêng nhưng khung là một.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;

  /// Nút tuỳ chọn TRƯỚC tiêu đề (vd: back của deck chủ đề).
  final Widget? leading;

  /// Các [HeaderActionButton] căn phải — giữ nguyên mọi action sẵn có.
  final List<Widget> actions;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.sm),
                action,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (showDivider) const WaveDivider(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Nút action header 44×44 thống nhất (tách từ _DeckHeaderButton của deck):
/// nền surface, viền ink 2, bo radiusButton, bóng hard — vùng chạm ≥44.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [AppShadows.hard],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
