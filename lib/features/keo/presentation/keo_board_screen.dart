import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../billing/application/billing_providers.dart';
import '../../discovery/application/discovery_providers.dart';
import '../application/keo_providers.dart';
import '../data/keo_errors.dart';
import '../domain/keo_match_suggestion.dart';
import 'keo_card.dart';
import 'keo_match_sheet.dart';

class KeoBoardScreen extends ConsumerWidget {
  const KeoBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keosAsync = ref.watch(openKeosProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isPro) {
            context.push('/keo/create');
          } else {
            _showProSheet(context);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo kèo'),
      ),
      body: SafeArea(
        child: keosAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 104),
            children: [
              _boardHeader(context),
              _matchBanner(context, ref),
              const SkeletonCard(),
              const SkeletonCard(),
              const SkeletonCard(),
            ],
          ),
          error: (err, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Không tải được danh sách kèo',
            subtitle: 'Kiểm tra kết nối rồi thử lại.',
            actionLabel: 'Thử lại',
            onAction: () => ref.invalidate(openKeosProvider),
          ),
          data: (keos) {
            if (keos.isEmpty) {
              return ListView(
                padding: const EdgeInsets.only(bottom: 104, top: AppSpacing.lg),
                children: [
                  _boardHeader(context),
                  _matchBanner(context, ref),
                  EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'Chưa có kèo quanh đây',
                    subtitle:
                        'Bấm ghép nhóm để tìm kèo hợp gu hoặc tự tạo một kèo mới.',
                    actionLabel: 'Tạo kèo đầu tiên',
                    onAction: () {
                      if (isPro) {
                        context.push('/keo/create');
                      } else {
                        _showProSheet(context);
                      }
                    },
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 104, top: AppSpacing.lg),
              itemCount: keos.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _boardHeader(context);
                if (index == 1) return _matchBanner(context, ref);
                final keo = keos[index - 2];
                return KeoCard(
                  keo: keo,
                  onTap: () => context.push(
                    '/keo/${keo.id}?title=${Uri.encodeComponent(keo.title)}',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showProSheet(BuildContext context) {
    ProUpsellSheet.show(context, variant: ProUpsellVariant.keoCreate);
  }

  Widget _boardHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kèo quanh bạn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Cửa hàng',
              onPressed: () => context.push('/store'),
              icon: const Icon(Icons.local_fire_department_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tìm nhóm đi hát hợp gu, gần bạn và có lịch phù hợp.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _matchBanner(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _runAutoMatch(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghép nhóm cho tôi',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tự động gợi ý kèo hợp gu, gần bạn và đúng khung giờ.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _runAutoMatch(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
    rootNavigator.push(loadingRoute);

    void dismissLoading() {
      if (rootNavigator.mounted && loadingRoute.isActive) {
        rootNavigator.removeRoute(loadingRoute);
      }
    }

    try {
      await ref.read(locationServiceProvider).captureAndPush();
      final suggestions = await ref.read(keoRepositoryProvider).suggestMatch();

      dismissLoading();
      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => KeoMatchSheet(
          suggestions: suggestions,
          onJoin: (suggestion) => _runSheetAction(
            context,
            () => _joinSuggestion(context, sheetContext, ref, suggestion),
          ),
          onCreate: (suggestion) => _runSheetAction(
            context,
            () => _createSuggestion(context, sheetContext, ref, suggestion),
          ),
        ),
      );
    } catch (e) {
      dismissLoading();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(keoErrorMessage(e))));
    }
  }

  Future<void> _runSheetAction(
    BuildContext boardContext,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (!boardContext.mounted) return;
      ScaffoldMessenger.of(
        boardContext,
      ).showSnackBar(SnackBar(content: Text(keoErrorMessage(e))));
    }
  }

  Future<void> _joinSuggestion(
    BuildContext boardContext,
    BuildContext sheetContext,
    WidgetRef ref,
    KeoMatchSuggestion suggestion,
  ) async {
    final keoId = suggestion.keoId;
    if (keoId == null) return;

    await ref.read(keoRepositoryProvider).requestJoin(keoId);
    ref.invalidate(openKeosProvider);
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    if (boardContext.mounted) {
      boardContext.push(
        '/keo/$keoId?title=${Uri.encodeComponent(suggestion.title)}',
      );
    }
  }

  Future<void> _createSuggestion(
    BuildContext boardContext,
    BuildContext sheetContext,
    WidgetRef ref,
    KeoMatchSuggestion suggestion,
  ) async {
    final start = DateTime.tryParse(suggestion.proposedStart ?? '');
    final end = DateTime.tryParse(suggestion.proposedEnd ?? '');
    if (start == null || end == null) {
      throw 'no_matchable_keo';
    }

    final id = await ref
        .read(keoRepositoryProvider)
        .createAutoMatchedKeo(
          title: suggestion.title,
          start: start,
          end: end,
          size: suggestion.sizeTarget,
          genres: suggestion.genres,
          joinMode: suggestion.joinMode,
        );
    ref.invalidate(openKeosProvider);
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    if (boardContext.mounted) {
      boardContext.push(
        '/keo/$id?title=${Uri.encodeComponent(suggestion.title)}',
      );
    }
  }
}
