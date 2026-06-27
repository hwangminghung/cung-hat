import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../billing/application/billing_providers.dart';
import '../application/keo_providers.dart';
import 'keo_card.dart';

class KeoBoardScreen extends ConsumerWidget {
  const KeoBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keosAsync = ref.watch(openKeosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kèo quanh bạn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ref.read(isProProvider)) {
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
            return EmptyState(
              icon: Icons.groups,
              title: 'Chưa có kèo quanh đây',
              subtitle: 'Hãy là người đầu tiên rủ mọi người đi hát.',
              actionLabel: 'Tạo kèo đầu tiên',
              onAction: () => context.push('/keo/create'),
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
            Text('Tạo kèo là tính năng Pro',
                style: Theme.of(sheetCtx).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Nâng cấp Pro để tự tạo kèo và tham gia không giới hạn.',
                textAlign: TextAlign.center),
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
                child: const Text('Để sau')),
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
        onTap: () => ref.invalidate(openKeosProvider),
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
                      'Tự động gợi ý kèo phù hợp (sắp có)',
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
}
