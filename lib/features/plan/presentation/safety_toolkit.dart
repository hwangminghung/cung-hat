import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../application/plan_providers.dart';

class SafetyToolkit extends ConsumerWidget {
  const SafetyToolkit({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.ios_share),
            label: const Text('Chia sẻ cho bạn bè'),
            onPressed: () async {
              final token =
                  await ref.read(planRepositoryProvider).createShareLink(planId);
              await SharePlus.instance.share(
                ShareParams(text: 'Mình đi hát, đây là kế hoạch: cunghat://plan/$token'),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            key: const Key('checkin_btn'),
            icon: const Icon(Icons.place),
            label: const Text('Tôi đã tới'),
            onPressed: () async {
              try {
                await ref.read(planRepositoryProvider).checkInArrived(planId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã ghi nhận bạn đã tới')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không ghi nhận được')),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
