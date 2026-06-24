import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/application/profile_providers.dart';
import '../application/keo_providers.dart';
import '../domain/keo_member.dart';

class KeoDetailScreen extends ConsumerWidget {
  const KeoDetailScreen({super.key, required this.keoId, required this.title});

  final String keoId;
  final String title;

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';
      case 'requested':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'left':
        return 'Đã rời';
      case 'declined':
        return 'Bị từ chối';
      default:
        return status;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(keoRosterProvider(keoId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: rosterAsync.when(
        data: (roster) => _buildBody(context, ref, roster),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Không tải được kèo')),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<KeoMember> roster) {
    final uid = ref.watch(myProfileProvider).value?.id;
    KeoMember? myRow;
    for (final m in roster) {
      if (m.userId == uid) {
        myRow = m;
        break;
      }
    }
    final isHost = myRow?.role == 'host';
    final isApproved = myRow?.joinStatus == 'approved';
    final notMember = myRow == null || myRow.joinStatus == 'left';

    return ListView(
      children: [
        for (final m in roster)
          ListTile(
            leading: CircleAvatar(
              child: Text(
                (m.displayName != null && m.displayName!.isNotEmpty)
                    ? m.displayName![0].toUpperCase()
                    : '?',
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(m.displayName ?? 'Ẩn danh')),
                if (m.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                ],
              ],
            ),
            subtitle: Text(
              m.role == 'host' ? 'Chủ kèo' : _statusText(m.joinStatus),
            ),
            trailing: (isHost && m.joinStatus == 'requested')
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Duyệt'),
                        onPressed: () async {
                          await ref
                              .read(keoRepositoryProvider)
                              .approve(keoId, m.userId);
                          ref.invalidate(keoRosterProvider(keoId));
                        },
                      ),
                      TextButton(
                        child: const Text('Từ chối'),
                        onPressed: () async {
                          await ref
                              .read(keoRepositoryProvider)
                              .decline(keoId, m.userId);
                          ref.invalidate(keoRosterProvider(keoId));
                        },
                      ),
                    ],
                  )
                : null,
          ),
        const SizedBox(height: 16),
        if (notMember)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              key: const Key('request_join_btn'),
              child: const Text('Xin vào kèo'),
              onPressed: () async {
                try {
                  await ref.read(keoRepositoryProvider).requestJoin(keoId);
                  ref.invalidate(keoRosterProvider(keoId));
                } catch (_) {
                  if (context.mounted) {
                    _snack(context, 'Không xin vào kèo được, thử lại');
                  }
                }
              },
            ),
          ),
        if (isApproved && !isHost)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              key: const Key('confirm_keo_btn'),
              child: const Text('Đồng ý tham gia'),
              onPressed: () async {
                await ref.read(keoRepositoryProvider).confirm(keoId);
                ref.invalidate(keoRosterProvider(keoId));
              },
            ),
          ),
        if (isApproved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              key: const Key('open_keo_chat_btn'),
              child: const Text('Mở chat nhóm'),
              onPressed: () => context.push('/keo/chat/$keoId'),
            ),
          ),
        if (isApproved && !isHost)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              child: const Text('Rời kèo'),
              onPressed: () async {
                await ref.read(keoRepositoryProvider).leave(keoId);
                ref.invalidate(keoRosterProvider(keoId));
              },
            ),
          ),
      ],
    );
  }
}
