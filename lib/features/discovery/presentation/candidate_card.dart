import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../photos/application/photo_providers.dart';
import '../../photos/presentation/photo_carousel.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

/// Card ứng viên trong deck. Chip thông tin dưới tên XOAY theo ảnh đang xem
/// (Tinder-parity mục 3c): ảnh 1 → khoảng cách + bài tủ chung; ảnh 2 → thể
/// loại chung; ảnh ≥3 → giới thiệu (bio). Khi hồ sơ có <2 ảnh, không có gì để
/// xoay theo nên hiện gộp như cũ (mọi chip cùng lúc).
class CandidateCard extends ConsumerStatefulWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onOpenDetail,
  });

  final Candidate candidate;

  /// Mở sheet chi tiết — trước đây là onTap của cả card, giờ đổi qua nút ⓘ
  /// vì tap trên ảnh giờ dùng để chuyển trang.
  final VoidCallback onOpenDetail;

  @override
  ConsumerState<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends ConsumerState<CandidateCard> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    final name = candidate.displayName ?? 'Bạn hát mới';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    final photoCount =
        (ref.watch(signedUrlsProvider(candidate.id)).value ?? const [])
            .length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              key: const Key('card_photo_area'),
              fit: StackFit.expand,
              children: [
                PhotoCarousel(
                  userId: candidate.id,
                  monogram: monogram,
                  swipeable: false,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  fallbackDecorations: [
                    Positioned(
                      left: -36,
                      top: 34,
                      child: Transform.rotate(
                        angle: -0.32,
                        child: Container(
                          width: 180,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -18,
                      bottom: 54,
                      child: Transform.rotate(
                        angle: 0.28,
                        child: Container(
                          width: 142,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                AppColors.tertiaryTint.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: IconButton.filledTonal(
                    tooltip: 'Báo cáo',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => ReportSheet(targetId: candidate.id),
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
                if (candidate.activeToday)
                  const Positioned(
                    left: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: _Badge(
                      icon: Icons.bolt_rounded,
                      label: 'Online hôm nay',
                      background: AppColors.secondary,
                      foreground: AppColors.secondaryDark,
                    ),
                  ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: IconButton.filledTonal(
                    key: const Key('card_detail_btn'),
                    tooltip: 'Xem hồ sơ',
                    onPressed: widget.onOpenDetail,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (candidate.verified)
                      const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: AppColors.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._infoChips(context, candidate, photoCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip dưới tên: <2 ảnh → gộp như cũ (không có gì để xoay theo); ≥2 ảnh →
  /// xoay theo [_photoIndex] — ảnh 1: khoảng cách + bài tủ; ảnh 2: thể loại
  /// chung; ảnh ≥3: giới thiệu (bio).
  List<Widget> _infoChips(
      BuildContext context, Candidate candidate, int photoCount) {
    if (photoCount < 2) {
      return [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Badge(
              icon: Icons.place_rounded,
              label: 'Cách ${candidate.distanceBand ?? '?'} km',
              background: AppColors.primaryTint,
              foreground: AppColors.primaryDark,
            ),
            _Badge(
              icon: Icons.music_note_rounded,
              label: 'cùng ${candidate.sharedBaitu.length} bài tủ',
              background: AppColors.tertiaryTint,
              foreground: AppColors.tertiary,
            ),
          ],
        ),
        if (candidate.sharedGenres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final genre in candidate.sharedGenres.take(3))
                _GenreChip(label: genre),
            ],
          ),
        ],
      ];
    }

    if (_photoIndex == 0) {
      return [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Badge(
              icon: Icons.place_rounded,
              label: 'Cách ${candidate.distanceBand ?? '?'} km',
              background: AppColors.primaryTint,
              foreground: AppColors.primaryDark,
            ),
            _Badge(
              icon: Icons.music_note_rounded,
              label: 'cùng ${candidate.sharedBaitu.length} bài tủ',
              background: AppColors.tertiaryTint,
              foreground: AppColors.tertiary,
            ),
          ],
        ),
      ];
    }

    if (_photoIndex == 1) {
      if (candidate.sharedGenres.isEmpty) {
        return [
          Text(
            'Chưa chung thể loại nào',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ];
      }
      return [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final genre in candidate.sharedGenres.take(5))
              _GenreChip(label: genre),
          ],
        ),
      ];
    }

    return [
      Text(
        candidate.bio?.trim().isNotEmpty == true
            ? candidate.bio!.trim()
            : 'Chưa có giới thiệu — hỏi thử khi match nhé!',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    ];
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '#$label',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
