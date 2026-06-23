import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/discovery_providers.dart';

const _reasons = ['spam', 'quấy rối', 'ảnh giả', 'khác'];

class ReportSheet extends ConsumerWidget {
  const ReportSheet({super.key, required this.targetId});
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final reason in _reasons)
            ListTile(
              title: Text('Báo cáo: $reason'),
              onTap: () => _report(context, ref, reason),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Chặn người này'),
            onTap: () => _block(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref, String reason) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(discoveryRepositoryProvider).reportUser(targetId, reason);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo.')));
    } catch (_) {
      nav.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Không gửi được báo cáo.')));
    }
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(discoveryRepositoryProvider).blockUser(targetId);
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Đã chặn.')));
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Không chặn được.')));
    }
  }
}
