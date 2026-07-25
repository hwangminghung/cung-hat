import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/hard_card.dart';
import '../application/admin_providers.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    String reportId,
    String action,
  ) async {
    try {
      await ref.read(moderationRepositoryProvider).action(reportId, action);
      ref.invalidate(openReportsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.adminActionFailed ??
                  'Thao tác thất bại',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final reportsAsync = ref.watch(openReportsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.adminTitle ?? 'Kiểm duyệt')),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Text(l10n?.adminEmpty ?? 'Không có báo cáo nào'),
            );
          }
          return ListView(
            children: [
              for (final r in reports)
                HardCard(
                  key: ValueKey(r.id),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: ListTile(
                    title: Text('${r.targetType} · ${r.reason ?? ''}'),
                    subtitle: Text(r.targetId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'hide'),
                          child: Text(l10n?.adminHide ?? 'Ẩn'),
                        ),
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'remove'),
                          child: Text(l10n?.adminRemove ?? 'Gỡ'),
                        ),
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'dismiss'),
                          child: Text(l10n?.adminDismiss ?? 'Bỏ qua'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(l10n?.adminLoadError ?? 'Không tải được báo cáo'),
        ),
      ),
    );
  }
}
