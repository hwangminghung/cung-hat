import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/wave_divider.dart';
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
  void didUpdateWidget(CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CardSwiper dựng card theo VỊ TRÍ (không key) nên State này có thể bị
    // tái dụng cho ứng viên khác khi deck tiến lên — reset chỉ số ảnh kẻo
    // card mới mở màn bằng chip bio của trang 3. (Deck cũng đã key theo
    // candidate.id; đây là lớp phòng thủ cho mọi đường tái dụng khác.)
    if (oldWidget.candidate.id != widget.candidate.id) _photoIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    final name = candidate.displayName ?? 'Bạn hát mới';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    final photoCount =
        (ref.watch(signedUrlsProvider(candidate.id)).value ?? const []).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppShadows.hard],
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
                            color: AppColors.tertiaryTint.withValues(
                              alpha: 0.70,
                            ),
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
                  child: _CardIconButton(
                    tooltip: 'Báo cáo',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => ReportSheet(targetId: candidate.id),
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
                if (candidate.activeToday)
                  const Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.md,
                    child: StampChip(
                      leadingIcon: Icons.circle,
                      label: 'Online hôm nay',
                      tone: StampChipTone.lime,
                    ),
                  ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _CardIconButton(
                    key: const Key('card_detail_btn'),
                    tooltip: 'Xem hồ sơ',
                    onTap: widget.onOpenDetail,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          const WaveDivider(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
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
    BuildContext context,
    Candidate candidate,
    int photoCount,
  ) {
    if (photoCount < 2) {
      return [
        _InfoLine(
          icon: Icons.place_rounded,
          label: 'Cách ${candidate.distanceBand ?? '?'} km',
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        _InfoLine(
          icon: Icons.music_note_rounded,
          label: 'cùng ${candidate.sharedBaitu.length} bài tủ',
          color: AppColors.teal,
        ),
        if (candidate.sharedGenres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final genre in candidate.sharedGenres.take(3))
                StampChip(label: '#$genre', tone: StampChipTone.teal),
            ],
          ),
        ],
      ];
    }

    if (_photoIndex == 0) {
      return [
        _InfoLine(
          icon: Icons.place_rounded,
          label: 'Cách ${candidate.distanceBand ?? '?'} km',
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        _InfoLine(
          icon: Icons.music_note_rounded,
          label: 'cùng ${candidate.sharedBaitu.length} bài tủ',
          color: AppColors.teal,
        ),
      ];
    }

    if (_photoIndex == 1) {
      if (candidate.sharedGenres.isEmpty) {
        return [
          Text(
            'Chưa chung thể loại nào',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ];
      }
      return [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final genre in candidate.sharedGenres.take(5))
              StampChip(label: '#$genre', tone: StampChipTone.teal),
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    ];
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
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
              child: IconTheme(
                data: const IconThemeData(color: AppColors.ink, size: 24),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
