import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/settings_providers.dart';

/// [DEBT] Danh sach "Da chan" — truoc day chan xong la mat dau vet: khong co
/// man nao liet ke va khong co duong bo chan. Bo chan chi go rao discovery/keo
/// tu gio; match cu da bi unmatch vinh vien (T&S), khong song lai.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final blocksAsync = ref.watch(myBlocksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsBlocked ?? 'Đã chặn')),
      body: KeyedSubtree(
        key: const Key('screen_blocked_users'),
        child: blocksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: SkeletonCard(),
          ),
          error: (_, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title:
                l10n?.blockedLoadError ??
                'Không tải được danh sách. Thử lại nhé.',
            actionLabel: l10n?.commonRetry ?? 'Thử lại',
            onAction: () => ref.invalidate(myBlocksProvider),
          ),
          data: (blocks) => blocks.isEmpty
              ? EmptyState(
                  icon: Icons.block_rounded,
                  title: l10n?.blockedEmptyTitle ?? 'Chưa chặn ai',
                  subtitle:
                      l10n?.blockedEmptySubtitle ??
                      'Người bạn chặn sẽ xuất hiện ở đây.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: blocks.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final b = blocks[i];
                    return HardCard(
                      key: Key('blocked_user_${b.userId}'),
                      child: ListTile(
                        leading: const Icon(Icons.person_off_outlined),
                        title: Text(
                          b.displayName ??
                              (l10n?.keoSharedAnonymous ?? 'Ẩn danh'),
                        ),
                        trailing: TextButton(
                          key: Key('unblock_${b.userId}'),
                          onPressed: () => _unblock(context, ref, b.userId),
                          child: Text(l10n?.blockedUnblock ?? 'Bỏ chặn'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    try {
      await ref.read(settingsRepositoryProvider).unblock(userId);
      ref.invalidate(myBlocksProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.blockedUnblockError ?? 'Không bỏ chặn được. Thử lại nhé.',
            ),
          ),
        );
      }
    }
  }
}
