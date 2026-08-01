import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/application/reference_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../domain/song_share.dart';
import '../../../shared/widgets/skeleton.dart';

/// Bottom sheet "Gửi bài tủ" (mockup 16): liệt kê bài tủ của mình, chọn một
/// bài trả về body đã encode ('♪ Title · Artist') — null nếu đóng sheet.
Future<String?> showSongShareSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => const _SongShareSheet(),
  );
}

class _SongShareSheet extends ConsumerWidget {
  const _SongShareSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baituIds = ref.watch(myBaituProvider).value;
    final songs = ref.watch(songsProvider).value;

    Widget body;
    if (baituIds == null || songs == null) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SkeletonTile(),
      );
    } else {
      final mine = songs.where((s) => baituIds.contains(s.id)).toList();
      if (mine.isEmpty) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            Localizations.of<AppLocalizations>(
                  context,
                  AppLocalizations,
                )?.songShareEmpty ??
                'Bạn chưa chọn bài tủ nào. Vào Hồ sơ để thêm nhé.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        body = ListView(
          shrinkWrap: true,
          children: [
            for (final song in mine)
              ListTile(
                key: ValueKey('share_song_${song.id}'),
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                ),
                title: Text(song.title),
                subtitle: Text(song.artist),
                onTap: () => Navigator.of(
                  context,
                ).pop(encodeSongShare(song.title, song.artist)),
              ),
          ],
        );
      }
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.chatShareSongTooltip ??
                  'Gửi bài tủ',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Flexible(child: body),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Nội dung bubble share bài hát — card nốt nhạc dùng chung cho chat 1-1 và
/// chat nhóm (mockup 16).
class SongShareContent extends StatelessWidget {
  const SongShareContent({super.key, required this.body, required this.mine});

  final String body;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final onColor = AppColors.ink;
    return Row(
      key: const Key('song_share_content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mine ? AppColors.onPrimary : AppColors.teal,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: AppColors.ink,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            songShareLabel(body),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
