import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
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
    // Watch (not read) so entitlements start loading when the board renders.
    final isPro = ref.watch(isProProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kèo quanh bạn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isPro) {
            context.push('/keo/create');
          } else {
            _showProSheet(context);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo kèo'),
      ),
      body: keosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.wifi_off,
          title: 'Không tải được danh sách kèo',
          subtitle: 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(openKeosProvider),
        ),
        data: (keos) {
          if (keos.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.sm),
              children: [
                _boardHeader(context),
                _matchBanner(context, ref),
                EmptyState(
                  icon: Icons.groups,
                  title: 'Chưa có kèo quanh đây',
                  subtitle: 'Hãy là người đầu tiên rủ mọi người đi hát.',
                  actionLabel: 'Tạo kèo đầu tiên',
                  onAction: () => context.push('/keo/create'),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.sm),
            itemCount: keos.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _boardHeader(context);
              if (index == 1) return _matchBanner(context, ref);
              final k = keos[index - 2];
              return KeoCard(
                keo: k,
                onTap: () => context.push(
                  '/keo/${k.id}?title=${Uri.encodeComponent(k.title)}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tạo kèo là tính năng Pro',
              style: Theme.of(sheetCtx).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nâng cấp Pro để tự tạo kèo và tham gia không giới hạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                context.push('/store');
              },
              child: const Text('Nâng cấp Pro'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetCtx),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tìm nhóm đi hát',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Cùng ghép một kèo hợp gu và gặp nhau ngoài đời.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _matchBanner(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        onTap: () => _runAutoMatch(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghép nhóm cho tôi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Tu dong goi y keo hop gu, gan ban',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
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
