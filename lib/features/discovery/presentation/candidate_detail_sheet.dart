import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../photos/presentation/photo_carousel.dart';
import '../../profile/domain/karaoke_prompts.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

/// Sheet chi tiết ứng viên (tap card để mở). Dữ liệu = những gì
/// get_discovery_candidates đã trả (sanitized, band-only) — không gọi thêm RPC.
///
/// Chế độ kép:
///  * Chế độ deck (mặc định, [onQuote] null): [onPass]/[onLike] bắt buộc về ý
///    nghĩa (deck luôn truyền cả 2), 2 nút THÍCH/BỎ QUA hiện; không có nút
///    "Trả lời" nào (giữ nguyên hành vi cũ 100%).
///  * Chế độ icebreaker (mở từ ChatScreen sau match, [onQuote] khác null):
///    ẩn 2 nút THÍCH/BỎ QUA (candidate đã match rồi, không cần swipe lại);
///    mỗi bài tủ chung / mỗi prompt / carousel ảnh có nút "Trả lời" gọi
///    [onQuote] với câu mồi rồi đóng sheet.
class CandidateDetailSheet extends StatelessWidget {
  const CandidateDetailSheet({
    super.key,
    required this.candidate,
    this.onPass,
    this.onLike,
    this.onQuote,
  });

  final Candidate candidate;
  final VoidCallback? onPass;
  final VoidCallback? onLike;

  /// Khác null = chế độ icebreaker (xem từ ChatScreen). Nhận câu mồi để
  /// prefill composer chat.
  final ValueChanged<String>? onQuote;

  static Future<void> show(
    BuildContext context, {
    required Candidate candidate,
    VoidCallback? onPass,
    VoidCallback? onLike,
    ValueChanged<String>? onQuote,
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
            onPass: onPass == null
                ? null
                : () {
                    Navigator.of(sheetCtx).pop();
                    onPass();
                  },
            onLike: onLike == null
                ? null
                : () {
                    Navigator.of(sheetCtx).pop();
                    onLike();
                  },
            onQuote: onQuote == null
                ? null
                : (q) {
                    Navigator.of(sheetCtx).pop();
                    onQuote(q);
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
          if (onQuote != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('quote_photo'),
                onPressed: () => onQuote!('Ảnh này xịn quá! '),
                child: const Text('Trả lời ảnh này'),
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
            for (final (i, song) in candidate.sharedBaitu.indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_rounded,
                    color: AppColors.primary),
                title: Text(song),
                trailing: onQuote == null
                    ? null
                    : TextButton(
                        key: Key('quote_baitu_$i'),
                        onPressed: () =>
                            onQuote!('Về bài "$song" của bạn: '),
                        child: const Text('Trả lời'),
                      ),
              ),
          for (final p in candidate.prompts)
            if (karaokePromptQuestion(p['prompt_id'] as String? ?? '') != null)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      karaokePromptQuestion(p['prompt_id'] as String)!,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${p['answer']}',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (onQuote != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: Key('quote_prompt_${p['prompt_id']}'),
                          onPressed: () => onQuote!(
                              'Bạn nói "${p['answer']}" — kể thêm đi: '),
                          child: const Text('Trả lời'),
                        ),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.xl),
          if (onPass != null || onLike != null)
            Row(
              children: [
                if (onPass != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('detail_pass_btn'),
                      onPressed: onPass,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Bỏ qua'),
                    ),
                  ),
                if (onPass != null && onLike != null)
                  const SizedBox(width: AppSpacing.md),
                if (onLike != null)
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
