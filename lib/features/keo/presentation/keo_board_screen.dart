import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/application/location_service.dart';
import '../../discovery/presentation/location_error_state.dart';
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: keosAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                  ),
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
                  title: Localizations.of<AppLocalizations>(
                              context, AppLocalizations)
                          ?.keoBoardLoadError ??
                      'Không tải được danh sách kèo',
                  subtitle: Localizations.of<AppLocalizations>(
                              context, AppLocalizations)
                          ?.commonCheckConnection ??
                      'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: Localizations.of<AppLocalizations>(
                              context, AppLocalizations)
                          ?.commonRetry ??
                      'Thử lại',
                  onAction: () => ref.invalidate(openKeosProvider),
                ),
                data: (keos) {
                  if (keos.isEmpty) {
                    // P0-1: board rỗng VÌ THIẾU VỊ TRÍ (list_open_keos cần vị
                    // trí đã lưu) phải nói đúng nguyên nhân thay vì "chưa có
                    // kèo". Status do deck Đôi (tab 0, mount trước) ghi.
                    final locStatus = ref.watch(locationStatusProvider);
                    final locationBlocked = locStatus != null &&
                        locStatus != LocationCaptureStatus.success;
                    return ListView(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.lg,
                        top: AppSpacing.lg,
                      ),
                      children: [
                        _boardHeader(context),
                        _matchBanner(context, ref),
                        if (locationBlocked)
                          LocationErrorState(
                            status: locStatus,
                            onRetry: () => _retryLocation(ref),
                            onOpenSettings: () => ref
                                .read(locationServiceProvider)
                                .openSettingsFor(locStatus),
                          )
                        else
                          // P2: board rỗng thật → "Ghép nhóm cho tôi" là CTA
                          // chính (một chạm ra gợi ý/proposal thay vì ngõ cụt).
                          EmptyState(
                            icon: Icons.groups_rounded,
                            title: Localizations.of<AppLocalizations>(
                                        context, AppLocalizations)
                                    ?.keoBoardEmptyTitle ??
                                'Chưa có kèo quanh đây',
                            subtitle: Localizations.of<AppLocalizations>(
                                        context, AppLocalizations)
                                    ?.keoBoardEmptySub ??
                                'Bấm ghép nhóm để tìm kèo hợp gu hoặc tự tạo một kèo mới.',
                            actionLabel: Localizations.of<AppLocalizations>(
                                        context, AppLocalizations)
                                    ?.keoBoardMatchMe ??
                                'Ghép nhóm cho tôi',
                            onAction: () => _runAutoMatch(context, ref),
                          ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.lg,
                      top: AppSpacing.lg,
                    ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  // P1-5 đảo gate: free được host 1 kèo active — client không
                  // chặn trước nữa, server raise free_host_limit khi vượt.
                  onPressed: () => context.push('/keo/create'),
                  icon: Icons.add_box_outlined,
                  child: Text(
                    Localizations.of<AppLocalizations>(context, AppLocalizations)
                            ?.keoCreateCta ??
                        'Tạo kèo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thử bắt + đẩy vị trí lại từ error state (P0-1); thành công thì fetch
  /// lại board (list_open_keos giờ mới có vị trí để tính khoảng cách).
  Future<void> _retryLocation(WidgetRef ref) async {
    final status = await ref.read(locationServiceProvider).captureAndPush();
    ref.read(locationStatusProvider.notifier).state = status;
    unawaited(ref.read(analyticsProvider).logLocationResult(
        granted: status != LocationCaptureStatus.permissionDenied));
    if (status == LocationCaptureStatus.success) {
      ref.invalidate(openKeosProvider);
    }
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
                Localizations.of<AppLocalizations>(context, AppLocalizations)
                        ?.keoBoardTitle ??
                    'Kèo quanh bạn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.outlined(
              tooltip: Localizations.of<AppLocalizations>(
                          context, AppLocalizations)
                      ?.keoBoardStoreTooltip ??
                  'Cửa hàng',
              onPressed: () => context.push('/store'),
              icon: const Icon(Icons.storefront_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Localizations.of<AppLocalizations>(context, AppLocalizations)
                  ?.keoBoardSubtitle ??
              'Tìm nhóm đi hát hợp gu, gần bạn và có lịch phù hợp.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: WaveDivider(),
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
    child: Pressable(
      onTap: () => _runAutoMatch(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          border: Border.all(color: AppColors.ink, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: const [AppShadows.hard],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.surface,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Localizations.of<AppLocalizations>(
                                  context, AppLocalizations)
                              ?.keoBoardMatchMe ??
                          'Ghép nhóm cho tôi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      Localizations.of<AppLocalizations>(
                                  context, AppLocalizations)
                              ?.keoBoardMatchMeSub ??
                          'Tự động gợi ý kèo hợp gu, gần bạn và đúng khung giờ.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.ink,
                ),
              ),
            ],
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
      final locStatus =
          await ref.read(locationServiceProvider).captureAndPush();
      // Ghi nguyên nhân cho empty state (P0-1); vẫn tiếp tục suggest — server
      // dùng vị trí ĐÃ LƯU nên có thể vẫn gợi ý được với vị trí cũ.
      ref.read(locationStatusProvider.notifier).state = locStatus;
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
    unawaited(ref.read(analyticsProvider).logKeoJoinRequest());
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
