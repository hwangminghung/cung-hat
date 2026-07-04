import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../photos/presentation/photo_carousel.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

/// Sheet chi tiết ứng viên (tap card để mở). Dữ liệu = những gì
/// get_discovery_candidates đã trả (sanitized, band-only) — không gọi thêm RPC.
class CandidateDetailSheet extends StatelessWidget {
  const CandidateDetailSheet({
    super.key,
    required this.candidate,
    required this.onPass,
    required this.onLike,
  });

  final Candidate candidate;
  final VoidCallback onPass;
  final VoidCallback onLike;

  static Future<void> show(
    BuildContext context, {
    required Candidate candidate,
    required VoidCallback onPass,
    required VoidCallback onLike,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: CandidateDetailSheet(
            candidate: candidate,
            onPass: () {
              Navigator.of(sheetCtx).pop();
              onPass();
            },
            onLike: () {
              Navigator.of(sheetCtx).pop();
              onLike();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = candidate.displayName ?? 'Bạn hát mới';
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    final monogram = name.isEmpty ? '?' : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 280,
            child: PhotoCarousel(
              userId: candidate.id,
              monogram: monogram,
              radius: BorderRadius.circular(AppSpacing.radiusCard),
              swipeable: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(monogram,
                    style: AppTypography.display(
                        fontSize: 28, color: AppColors.onPrimary)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (candidate.verified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.verified_rounded,
                            size: 20, color: AppColors.tertiary),
                      ],
                    ]),
                    Text('Cách ${candidate.distanceBand ?? '?'} km',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Gu nhạc chung',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedGenres.isEmpty)
            Text('Chưa trùng thể loại nào.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in candidate.sharedGenres)
                  Chip(label: Text('#$g')),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bài tủ chung',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedBaitu.isEmpty)
            Text('Chưa có bài tủ chung — cơ hội khám phá!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else
            for (final song in candidate.sharedBaitu)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_rounded,
                    color: AppColors.primary),
                title: Text(song),
              ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('detail_pass_btn'),
                  onPressed: onPass,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Bỏ qua'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('detail_like_btn'),
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Thích'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              key: const Key('detail_report_btn'),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => ReportSheet(targetId: candidate.id),
              ),
              child: const Text('Báo cáo / Chặn'),
            ),
          ),
        ],
      ),
    );
  }
}
