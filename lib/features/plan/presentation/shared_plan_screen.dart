import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/datetime_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hard_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/plan_providers.dart';

class SharedPlanScreen extends ConsumerWidget {
  const SharedPlanScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final async = ref.watch(resolveShareProvider(token));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.planSharedTitle ?? 'Kế hoạch được chia sẻ'),
      ),
      // [UI-AUDIT] Đồng khuôn SharedKeoScreen: Skeleton khi tải, lỗi MẠNG ra
      // EmptyState + Thử lại (trước đây mọi lỗi đều thành "Không tìm thấy kế
      // hoạch" — nói dối user đang offline), chỉ báo không-tồn-tại khi server
      // trả null thật.
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          children: const [SkeletonTile(), SkeletonTile()],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: l10n?.planSharedLoadError ?? 'Không tải được kế hoạch',
          subtitle:
              l10n?.commonCheckConnection ?? 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: l10n?.commonRetry ?? 'Thử lại',
          onAction: () => ref.invalidate(resolveShareProvider(token)),
        ),
        data: (data) {
          if (data['venue_name'] == null) {
            return EmptyState(
              icon: Icons.link_off_rounded,
              title: l10n?.planSharedNotFound ?? 'Không tìm thấy kế hoạch',
            );
          }
          if (data['expired'] == true) {
            return EmptyState(
              icon: Icons.schedule_rounded,
              title: l10n?.keoSharedExpired ?? 'Liên kết đã hết hạn',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: HardCard(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['venue_name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${data['address'] ?? ''}'),
                    const SizedBox(height: 8),
                    // [AUDIT] Cung loi ISO tho nhu PlanScreen: man hinh nay la
                    // thu nguoi duoc chia se link nhin thay dau tien.
                    Text(
                      formatLocalDateTime(data['scheduled_at'] as String?) ??
                          '${data['scheduled_at'] ?? ''}',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
