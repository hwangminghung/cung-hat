import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/discovery_providers.dart';
import '../data/discovery_errors.dart';
import '../domain/candidate.dart';

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  /// [MATCH-AUDIT #4b] Người trong danh sách này ĐÃ like mình, nên "thích
  /// lại" tạo match ngay trong record_swipe — trước đây màn trả phí 99k chỉ
  /// cho NHÌN rồi bắt user ngồi chờ gặp lại đúng người đó trong deck.
  Future<void> _likeBack(
    BuildContext context,
    WidgetRef ref,
    Candidate person,
  ) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final matched = await ref
          .read(discoveryRepositoryProvider)
          .recordSwipe(person.id, 'like');
      // Match rồi thì who_liked_me không trả người này nữa — refresh cho row
      // biến mất thay vì để nút bấm lại lần hai.
      ref.invalidate(whoLikedMeProvider);
      final name = person.displayName ?? (l10n?.likesAnonymous ?? 'Ẩn danh');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            matched
                ? (l10n?.likesMatched(name) ??
                      'Đã ghép đôi với $name! Vào Tin nhắn bắt chuyện nhé.')
                : (l10n?.likesLikeSent ?? 'Đã gửi lượt thích.'),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(discoverySwipeError(e).localizedMessage(l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final likes = ref.watch(whoLikedMeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.shellTileLikes ?? 'Ai đã thích bạn')),
      body: likes.when(
        data: (people) {
          if (people.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_rounded,
              title: l10n?.likesEmptyTitle ?? 'Chưa có ai thích bạn',
              subtitle:
                  l10n?.likesEmptySub ??
                  'Cứ hát hết mình, người hợp gu sẽ tới.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              for (final person in people)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _monogram(person.displayName),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.onPrimary),
                      ),
                    ),
                    title: Text(
                      person.displayName ?? (l10n?.likesAnonymous ?? 'Ẩn danh'),
                    ),
                    trailing: FilledButton.icon(
                      key: Key('like_back_${person.id}'),
                      onPressed: () => _likeBack(context, ref, person),
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: Text(l10n?.likesLikeBack ?? 'Thích lại'),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          children: const [SkeletonTile(), SkeletonTile(), SkeletonTile()],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.lock_rounded,
          title: l10n?.likesLockedTitle ?? 'Mở khóa để xem ai đã thích bạn',
          actionLabel: l10n?.storeTitle ?? 'Nâng cấp',
          onAction: () => context.push('/store'),
        ),
      ),
    );
  }

  String _monogram(String? name) {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}
