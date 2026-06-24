import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/keo_providers.dart';
import 'keo_card.dart';

class KeoBoardScreen extends ConsumerWidget {
  const KeoBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keosAsync = ref.watch(openKeosProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/keo/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo kèo'),
      ),
      body: keosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            const Center(child: Text('Không tải được danh sách kèo')),
        data: (keos) {
          if (keos.isEmpty) {
            return const Center(child: Text('Chưa có kèo nào quanh đây'));
          }
          return ListView.builder(
            itemCount: keos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Ghép nhóm cho tôi'),
                    subtitle: const Text('Tự động gợi ý kèo phù hợp (sắp có)'),
                    onTap: () => ref.invalidate(openKeosProvider),
                  ),
                );
              }
              final k = keos[index - 1];
              return KeoCard(
                keo: k,
                onTap: () => context.push(
                    '/keo/${k.id}?title=${Uri.encodeComponent(k.title)}'),
              );
            },
          );
        },
      ),
    );
  }
}
