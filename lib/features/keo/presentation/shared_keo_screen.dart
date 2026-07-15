import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../auth/application/auth_providers.dart';
import '../application/keo_providers.dart';
import '../domain/shared_keo.dart';

/// Public (login-optional) screen resolved from a "chia sẻ kèo" deep-link
/// token — mirrors lib/features/plan/presentation/shared_plan_screen.dart's
/// role in the plan-sharing flow, extended with typed states (loading/error/
/// not-found/expired) and a session-aware bottom CTA.
class SharedKeoScreen extends ConsumerWidget {
  const SharedKeoScreen({super.key, required this.token});

  final String token;

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatTime(String? start) {
    final at = start == null ? null : DateTime.tryParse(start);
    if (at == null) return '?';
    final local = at.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final async = ref.watch(sharedKeoProvider(token));
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.keoSharedTitle ?? 'Kèo được chia sẻ')),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          children: const [SkeletonTile(), SkeletonTile()],
        ),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: l10n?.keoSharedLoadError ?? 'Không tải được kèo',
          subtitle: l10n?.commonCheckConnection ?? 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: l10n?.commonRetry ?? 'Thử lại',
          onAction: () => ref.invalidate(sharedKeoProvider(token)),
        ),
        data: (keo) {
          if (keo == null) {
            return EmptyState(
              icon: Icons.link_off_rounded,
              title: l10n?.keoSharedNotFound ?? 'Không tìm thấy kèo',
              subtitle: l10n?.keoSharedNotFoundSub ?? 'Link không đúng hoặc kèo đã bị xoá.',
            );
          }
          if (keo.expired) {
            return EmptyState(
              icon: Icons.schedule_rounded,
              title: l10n?.keoSharedExpired ?? 'Link đã hết hạn',
            );
          }
          return _SharedKeoBody(keo: keo, formatTime: _formatTime);
        },
      ),
    );
  }
}

class _SharedKeoBody extends ConsumerWidget {
  const _SharedKeoBody({required this.keo, required this.formatTime});

  final SharedKeo keo;
  final String Function(String?) formatTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final signedIn = ref.watch(isSignedInProvider);
    final open = keo.joinMode == 'open';
    final modeLabel = open
        ? (l10n?.keoModeOpen ?? 'Mở · vào là tham gia')
        : (l10n?.keoModeApproval ?? 'Cần duyệt');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HardCard(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keo.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '🕗 ${formatTime(keo.timeWindowStart)} · ${keo.areaLabel ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n?.keoSharedSeats(keo.slotsFilled, keo.sizeTarget) ??
                        '${keo.slotsFilled}/${keo.sizeTarget} chỗ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: open
                          ? AppColors.secondary.withValues(alpha: 0.62)
                          : AppColors.tertiaryTint,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      modeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: open
                            ? AppColors.secondaryDark
                            : AppColors.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (keo.genres.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final genre in keo.genres)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n != null
                        ? l10n.keoSharedHost(
                            keo.hostName ?? l10n.keoSharedAnonymous)
                        : 'Host: ${keo.hostName ?? 'Ẩn danh'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (signedIn)
            FilledButton(
              key: const Key('shared_keo_open_btn'),
              onPressed: () => context.push('/keo/${keo.keoId}'),
              child: Text(l10n?.keoSharedJoinCta ?? 'Xem kèo & xin vào'),
            )
          else
            FilledButton(
              key: const Key('shared_keo_login_btn'),
              onPressed: () => context.push('/auth'),
              child: Text(l10n?.keoSharedLoginCta ?? 'Đăng nhập để xin vào'),
            ),
        ],
      ),
    );
  }
}
