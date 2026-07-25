import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/discovery_providers.dart';

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

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
