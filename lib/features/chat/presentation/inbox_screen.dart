import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/inbox_providers.dart';

/// Matches inbox hosted on the Chat tab: list of active matches with unread
/// badges. Tapping a row opens the 1-1 chat thread.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(child: Text('Chưa có cuộc trò chuyện nào'));
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, i) {
            final m = matches[i];
            final monogram =
                m.otherName.isEmpty ? '?' : m.otherName.characters.first;
            return ListTile(
              leading: CircleAvatar(child: Text(monogram)),
              title: Text(m.otherName),
              trailing: m.unread > 0 ? _UnreadBadge(count: m.unread) : null,
              onTap: () => context.go(
                '/chat/${m.matchId}?name=${Uri.encodeComponent(m.otherName)}',
              ),
            );
          },
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
