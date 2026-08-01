import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../onboarding/application/reference_providers.dart';
import '../../onboarding/domain/music_ref.dart';
import '../../photos/presentation/photo_carousel.dart';
import '../../profile/domain/karaoke_prompts.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

/// Sheet chi tiết ứng viên (tap card để mở). Dữ liệu = những gì
/// get_discovery_candidates đã trả (sanitized, band-only) — không gọi thêm RPC.
///
/// Chế độ kép:
///  * [onPass] và [onLike] điều khiển độc lập từng hành động deck.
///  * [onQuote] điều khiển độc lập các nút icebreaker trên ảnh, bài tủ, prompt.
/// Caller có thể truyền bất kỳ tổ hợp callback nào; [show] luôn đóng sheet
/// trước rồi mới gọi callback tương ứng.
class CandidateDetailSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final name =
        candidate.displayName ?? (l10n?.candidateFallbackName ?? 'Bạn hát mới');
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    final monogram = name.isEmpty ? '?' : name[0].toUpperCase();

    // shared_baitu giữ SONG ID thô ('s1'..) — resolve tên hiển thị qua bảng
    // songs (songsProvider, reference đã cache). Đang loading/lỗi → map rỗng
    // → fallback hiện raw id, KHÔNG chặn render.
    final songs = ref.watch(songsProvider).value ?? const <Song>[];
    final titleById = {for (final s in songs) s.id: s.title};
    final knownPrompts = candidate.prompts.where(
      (prompt) =>
          karaokePromptQuestion(prompt['prompt_id'] as String? ?? '') != null,
    );

    return Padding(
      key: const Key('screen_08_doi_profile_detail'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              key: const Key('detail_sheet_handle'),
              width: 72,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (candidate.verified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.verified_rounded,
                            size: 22,
                            color: AppColors.teal,
                          ),
                        ],
                        // [AUDIT SAFETY] Loi bao cao phai thay ngay canh ten:
                        // nut cu nam duoi cung, user phai cuon qua anh, gu
                        // nhac va prompt moi toi duoc. Nut cuoi trang GIU
                        // NGUYEN (detail_report_btn) cho luong da quen.
                        IconButton(
                          key: const Key('detail_report_header_btn'),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            builder: (_) => ReportSheet(targetId: candidate.id),
                          ),
                          icon: const Icon(Icons.shield_outlined),
                          tooltip:
                              l10n?.safetyReportTooltip ?? 'Báo cáo hoặc chặn',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 20,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n?.candidateDistanceKm(
                                  candidate.distanceBand ?? '?',
                                ) ??
                                'Cách ${candidate.distanceBand ?? '?'} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onQuote != null) ...[
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('quote_photo'),
                  onPressed: () => onQuote!(
                    l10n?.candidatePhotoQuote ?? 'Ảnh này xịn quá! ',
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n?.candidateReplyPhoto ?? 'Trả lời ảnh này'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              boxShadow: [AppShadows.hard],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard - 2),
              child: SizedBox(
                height: 280,
                child: PhotoCarousel(
                  userId: candidate.id,
                  monogram: monogram,
                  radius: BorderRadius.zero,
                  swipeable: true,
                ),
              ),
            ),
          ),
          const WaveDivider(height: AppSpacing.xxl),
          Text(
            l10n?.candidateSharedGenresTitle ?? 'Gu nhạc chung',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedGenres.isEmpty)
            Text(
              l10n?.candidateNoSharedGenresDot ?? 'Chưa trùng thể loại nào.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in candidate.sharedGenres)
                  StampChip(label: '#$g', tone: StampChipTone.teal),
              ],
            ),
          const WaveDivider(height: AppSpacing.xxl),
          Text(
            l10n?.candidateSharedBaituTitle ?? 'Bài tủ chung',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedBaitu.isEmpty)
            Text(
              l10n?.candidateNoSharedBaitu ??
                  'Chưa có bài tủ chung — cơ hội khám phá!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final (i, song) in candidate.sharedBaitu.indexed)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        border: Border(
                          right: BorderSide(color: AppColors.ink, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        titleById[song] ?? song,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (onQuote != null)
                      TextButton(
                        key: Key('quote_baitu_$i'),
                        onPressed: () => onQuote!(
                          l10n?.candidateSongQuote(titleById[song] ?? song) ??
                              'Về bài "${titleById[song] ?? song}" của bạn: ',
                        ),
                        child: Text(l10n?.candidateReply ?? 'Trả lời'),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ),
              ),
          for (final prompt in knownPrompts)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                boxShadow: [AppShadows.hard],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    karaokePromptQuestion(prompt['prompt_id'] as String)!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${prompt['answer']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (onQuote != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: Key('quote_prompt_${prompt['prompt_id']}'),
                        onPressed: () => onQuote!(
                          l10n?.candidatePromptQuote('${prompt['answer']}') ??
                              'Bạn nói "${prompt['answer']}" — kể thêm đi: ',
                        ),
                        child: Text(l10n?.candidateReply ?? 'Trả lời'),
                      ),
                    ),
                ],
              ),
            ),
          const WaveDivider(height: AppSpacing.xxl),
          if (onPass != null || onLike != null)
            Row(
              children: [
                if (onPass != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('detail_pass_btn'),
                      onPressed: onPass,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n?.discoveryPass ?? 'Bỏ qua'),
                    ),
                  ),
                if (onPass != null && onLike != null)
                  const SizedBox(width: AppSpacing.md),
                if (onLike != null)
                  Expanded(
                    child: GradientButton(
                      key: const Key('detail_like_btn'),
                      onPressed: onLike,
                      icon: Icons.favorite_rounded,
                      child: Text(l10n?.discoveryLike ?? 'Thích'),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              key: const Key('detail_report_btn'),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => ReportSheet(targetId: candidate.id),
              ),
              icon: const Icon(Icons.shield_outlined),
              label: Text(l10n?.candidateReportBlock ?? 'Báo cáo / Chặn'),
            ),
          ),
        ],
      ),
    );
  }
}
