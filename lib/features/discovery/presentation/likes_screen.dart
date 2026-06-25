import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/discovery_providers.dart';

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(whoLikedMeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ai đã thích bạn')),
      body: likes.when(
        data: (people) {
          if (people.isEmpty) {
            return const Center(child: Text('Chưa có ai thích bạn'));
          }
          return ListView(
            children: [
              for (final p in people)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(_monogram(p.displayName)),
                  ),
                  title: Text(p.displayName ?? 'Ẩn danh'),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mở khoá để xem ai đã thích bạn'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push('/store'),
                child: const Text('Nâng cấp'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monogram(String? name) {
    final n = (name ?? '').trim();
    return n.isEmpty ? '?' : n.characters.first.toUpperCase();
  }
}
