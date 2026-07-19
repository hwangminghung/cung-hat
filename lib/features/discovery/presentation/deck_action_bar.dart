import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Hàng nút hành động dưới deck. Thuần UI — mọi logic (gate Pro, quota,
/// controller.swipe) do DoiDeckScreen quyết định qua callback.
///
/// [hProgress]/[vProgress] (-1..1, cùng đơn vị với [SwipeOverlays]) đồng bộ
/// hiệu ứng nhấn mạnh nút với chiều đang kéo card (Tinder-parity mục 3):
/// kéo phải → nút thích phóng to; kéo trái → nút bỏ qua; kéo lên → nút siêu
/// thích. Mặc định 0 (không kéo) → mọi nút ở scale bình thường.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.rewindEnabled,
    this.hProgress = 0,
    this.vProgress = 0,
  });

  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  /// false = user free: nút vẫn tap được nhưng mờ; caller mở Pro upsell.
  final bool rewindEnabled;

  final double hProgress;
  final double vProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final passEmphasis = (-hProgress).clamp(0.0, 1.0);
    final likeEmphasis = hProgress.clamp(0.0, 1.0);
    final superEmphasis = (-vProgress).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: Opacity(
            // The free-user rewind remains actionable (it opens the Pro
            // explanation), so keep its label above normal-text contrast.
            opacity: rewindEnabled ? 1 : 0.8,
            child: _ActionItem(
              key: const Key('deck_rewind_btn'),
              icon: Icons.fast_rewind_rounded,
              label: l10n?.discoveryRewind ?? 'Quay lại',
              accent: AppColors.secondary,
              onTap: onRewind,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionItem(
            key: const Key('deck_pass_btn'),
            icon: Icons.close_rounded,
            label: l10n?.discoveryPass ?? 'Bỏ qua',
            accent: AppColors.surface,
            onTap: onPass,
            emphasis: passEmphasis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionItem(
            key: const Key('deck_super_btn'),
            icon: Icons.star_rounded,
            label: l10n?.discoverySuperLike ?? 'Siêu thích',
            accent: AppColors.teal,
            onTap: onSuperLike,
            emphasis: superEmphasis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionItem(
            key: const Key('deck_like_btn'),
            icon: Icons.favorite_rounded,
            label: l10n?.discoveryLike ?? 'Thích',
            accent: AppColors.primary,
            foreground: AppColors.onPrimary,
            onTap: onLike,
            emphasis: likeEmphasis,
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.foreground = AppColors.ink,
    this.emphasis = 0.0,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color foreground;
  final VoidCallback onTap;

  /// 0..1 — mức kéo theo chiều nút này đại diện. 0 = bình thường; 1 = đang
  /// kéo hết cỡ về hướng này (nút to hơn, viền đậm hơn, nền bắt đầu nhuốm màu).
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    void activate() {
      HapticFeedback.lightImpact();
      onTap();
    }

    return Semantics(
      label: label,
      button: true,
      onTap: activate,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 1 + 0.15 * emphasis,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    accent,
                    accent.withValues(alpha: 0.72),
                    emphasis,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  border: Border.all(color: AppColors.ink, width: 2 + emphasis),
                  boxShadow: const [AppShadows.hard],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: activate,
                    child: SizedBox.square(
                      dimension: 54,
                      child: Icon(icon, color: foreground, size: 28),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // UI review: nhãn 11px khó đọc — nâng lên labelMedium (12px+) và giữ
            // 1 dòng; khoảng cách dưới do padding của bar trong doi_deck lo.
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
