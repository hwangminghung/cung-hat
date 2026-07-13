import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/discovery_providers.dart';
import '../domain/like_teaser.dart';

/// Màn teaser "Ai đã thích bạn" cho user FREE: lưới card mosaic (ảnh đã làm
/// mờ server-side — client không bao giờ nhận URL ảnh gốc, không id/tên),
/// kèm chip tuổi/tick/1 genre chung + CTA mở khoá Pro. User có `see_likes`
/// không vào đây — home_shell đẩy thẳng /likes như cũ.
class LikesTeaserScreen extends ConsumerWidget {
  const LikesTeaserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teasers = ref.watch(likesTeaserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ai đã thích bạn')),
      body: teasers.when(
        loading: () => GridView.count(
          padding: const EdgeInsets.all(AppSpacing.lg),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.72,
          children: const [
            Skeleton(radius: AppSpacing.radiusCard),
            Skeleton(radius: AppSpacing.radiusCard),
            Skeleton(radius: AppSpacing.radiusCard),
            Skeleton(radius: AppSpacing.radiusCard),
          ],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được danh sách',
          subtitle: 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(likesTeaserProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có ai thích bạn',
              subtitle: 'Hoàn thiện hồ sơ để được thấy nhiều hơn nhé.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  '${list.length} người đã thích bạn',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _TeaserCard(index: i, teaser: list[i]),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: FilledButton.icon(
                    key: const Key('teaser_unlock_btn'),
                    onPressed: () => ProUpsellSheet.show(
                      context,
                      variant: ProUpsellVariant.seeLikes,
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Mở khoá với Pro — xem ai thích bạn'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeaserCard extends StatelessWidget {
  const _TeaserCard({required this.index, required this.teaser});

  final int index;
  final LikeTeaser teaser;

  /// Fallback khi không có ảnh (liker chưa up ảnh) hoặc ảnh mosaic tải lỗi.
  Widget _personFallback() => Container(
    decoration: const BoxDecoration(gradient: AppColors.brandGradient),
    child: const Icon(
      Icons.person_rounded,
      size: 56,
      color: AppColors.onPrimary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.onPrimary,
      fontWeight: FontWeight.w800,
    );
    return HardCard(
      key: Key('teaser_card_$index'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (teaser.teaserUrl != null)
            Image.network(
              teaser.teaserUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _personFallback(),
            )
          else
            _personFallback(),
          // Scrim đáy cho chip nổi trên ảnh — AppColors chưa có token scrim,
          // dùng black54→transparent trực tiếp.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Text('${teaser.age ?? "?"}', style: labelStyle),
                  if (teaser.verified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.onPrimary,
                    ),
                  ],
                  if (teaser.sharedGenre != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '#${teaser.sharedGenre}',
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
