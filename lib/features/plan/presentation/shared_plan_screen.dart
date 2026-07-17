import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/hard_card.dart';
import '../application/plan_providers.dart';

class SharedPlanScreen extends ConsumerWidget {
  const SharedPlanScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final async = ref.watch(resolveShareProvider(token));
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.planSharedTitle ?? 'Kế hoạch được chia sẻ')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(l10n?.planSharedNotFound ?? 'Không tìm thấy kế hoạch'),
        ),
        data: (data) {
          if (data['venue_name'] == null) {
            return Center(
              child: Text(l10n?.planSharedNotFound ?? 'Không tìm thấy kế hoạch'),
            );
          }
          if (data['expired'] == true) {
            return Center(
              child: Text(l10n?.keoSharedExpired ?? 'Liên kết đã hết hạn'),
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
                    Text('${data['scheduled_at'] ?? ''}'),
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
