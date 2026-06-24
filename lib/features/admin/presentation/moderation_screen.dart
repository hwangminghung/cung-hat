import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thao tác thất bại')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(openReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt')),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text('Không có báo cáo nào'));
          }
          return ListView(
            children: [
              for (final r in reports)
                Card(
                  key: ValueKey(r.id),
                  child: ListTile(
                    title: Text('${r.targetType} · ${r.reason ?? ''}'),
                    subtitle: Text(r.targetId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'hide'),
                          child: const Text('Ẩn'),
                        ),
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'remove'),
                          child: const Text('Gỡ'),
                        ),
                        TextButton(
                          onPressed: () => _act(context, ref, r.id, 'dismiss'),
                          child: const Text('Bỏ qua'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Không tải được báo cáo')),
      ),
    );
  }
}
