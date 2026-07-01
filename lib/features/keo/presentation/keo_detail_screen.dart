import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/application/profile_providers.dart';
import '../application/keo_providers.dart';
import '../data/keo_errors.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

class KeoDetailScreen extends ConsumerWidget {
  const KeoDetailScreen({super.key, required this.keoId, required this.title});

  final String keoId;
  final String title;

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Da duyet';
      case 'requested':
        return 'Cho duyet';
      case 'confirmed':
        return 'Da xac nhan';
      case 'left':
        return 'Da roi';
      case 'declined':
        return 'Bi tu choi';
      default:
        return status;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(keoDetailProvider(keoId));
    final rosterAsync = ref.watch(keoRosterProvider(keoId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: detailAsync.when(
        data: (keo) => rosterAsync.when(
          data: (roster) => _buildBody(context, ref, keo, roster),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Khong tai duoc keo')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Khong tai duoc keo')),
      ),
    );
  }

  void _confirmBoost(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Day keo nay?'),
        content: const Text(
          'Dung 1 luot day de dua keo len dau bang trong 24 gio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('De sau'),
          ),
          FilledButton(
            key: const Key('confirm_boost_keo_btn'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(keoRepositoryProvider).applyBoost(keoId);
                ref.invalidate(keoDetailProvider(keoId));
                ref.invalidate(openKeosProvider);
                if (context.mounted) _snack(context, 'Da day keo');
              } catch (e) {
                if (!context.mounted) return;
                if (keoErrorCode(e) == 'no_boost_credit') {
                  showDialog<void>(
                    context: context,
                    builder: (buyContext) => AlertDialog(
                      content: Text(keoErrorMessage(e)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(buyContext),
                          child: const Text('De sau'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(buyContext);
                            context.push('/store');
                          },
                          child: const Text('Mua luot day'),
                        ),
                      ],
                    ),
                  );
                } else {
                  _snack(context, keoErrorMessage(e));
                }
              }
            },
            child: const Text('Day keo'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Keo keo,
    List<KeoMember> roster,
  ) {
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
            key: ValueKey(m.userId),
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
                Flexible(child: Text(m.displayName ?? 'An danh')),
                if (m.verified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                ],
              ],
            ),
            subtitle: Text(
              m.role == 'host' ? 'Chu keo' : _statusText(m.joinStatus),
            ),
            trailing: (isHost && m.joinStatus == 'requested')
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Duyet'),
                        onPressed: () async {
                          try {
                            await ref
                                .read(keoRepositoryProvider)
                                .approve(keoId, m.userId);
                            ref.invalidate(keoRosterProvider(keoId));
                          } catch (_) {
                            if (context.mounted) {
                              _snack(context, 'Khong duyet duoc');
                            }
                          }
                        },
                      ),
                      TextButton(
                        child: const Text('Tu choi'),
                        onPressed: () async {
                          try {
                            await ref
                                .read(keoRepositoryProvider)
                                .decline(keoId, m.userId);
                            ref.invalidate(keoRosterProvider(keoId));
                          } catch (_) {
                            if (context.mounted) {
                              _snack(context, 'Khong tu choi duoc');
                            }
                          }
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
              child: const Text('Xin vao keo'),
              onPressed: () async {
                try {
                  await ref.read(keoRepositoryProvider).requestJoin(keoId);
                  ref.invalidate(keoRosterProvider(keoId));
                } catch (e) {
                  if (!context.mounted) return;
                  if (keoErrorCode(e) == 'free_join_limit') {
                    showDialog<void>(
                      context: context,
                      builder: (d) => AlertDialog(
                        content: Text(keoErrorMessage(e)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d),
                            child: const Text('De sau'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(d);
                              context.push('/store');
                            },
                            child: const Text('Nang cap Pro'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _snack(context, keoErrorMessage(e));
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
              child: const Text('Dong y tham gia'),
              onPressed: () async {
                try {
                  await ref.read(keoRepositoryProvider).confirm(keoId);
                  ref.invalidate(keoRosterProvider(keoId));
                } catch (_) {
                  if (context.mounted) {
                    _snack(context, 'Khong xac nhan duoc');
                  }
                }
              },
            ),
          ),
        if (isApproved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              key: const Key('open_keo_chat_btn'),
              child: const Text('Mo chat nhom'),
              onPressed: () => context.push('/keo/chat/$keoId'),
            ),
          ),
        if (isHost)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              key: const Key('host_pick_venue_btn'),
              child: const Text('Chot quan'),
              onPressed: () => context.push('/keo/plan/$keoId?host=1'),
            ),
          ),
        if (isHost && keo.isBoosted)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Keo dang duoc day'),
              subtitle: Text('Keo cua ban dang o nhom noi bat.'),
            ),
          ),
        if (isHost && !keo.isBoosted && keo.status == 'open')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              key: const Key('boost_keo_btn'),
              icon: const Icon(Icons.trending_up),
              label: const Text('Day keo'),
              onPressed: () => _confirmBoost(context, ref),
            ),
          ),
        if (!isHost && isApproved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              key: const Key('view_plan_btn'),
              child: const Text('Xem ke hoach'),
              onPressed: () => context.push('/keo/plan/$keoId'),
            ),
          ),
        if (isApproved && !isHost)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              child: const Text('Roi keo'),
              onPressed: () async {
                try {
                  await ref.read(keoRepositoryProvider).leave(keoId);
                  ref.invalidate(keoRosterProvider(keoId));
                } catch (_) {
                  if (context.mounted) {
                    _snack(context, 'Khong roi keo duoc');
                  }
                }
              },
            ),
          ),
      ],
    );
  }
}
