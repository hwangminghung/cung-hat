import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../application/plan_providers.dart';

class SafetyToolkit extends ConsumerWidget {
  const SafetyToolkit({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.ios_share),
            label: Text(l10n?.safetyShare ?? 'Chia sẻ cho bạn bè'),
            onPressed: () async {
              try {
                final token = await ref
                    .read(planRepositoryProvider)
                    .createShareLink(planId);
                final link = 'cunghat://plan/$token';
                await SharePlus.instance.share(
                  ShareParams(
                    text:
                        l10n?.safetyShareMessage(link) ??
                        'Mình đi hát, đây là kế hoạch: $link',
                  ),
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.safetyShareError ??
                            'Không tạo được liên kết chia sẻ',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            key: const Key('checkin_btn'),
            icon: const Icon(Icons.place),
            label: Text(l10n?.safetyArrived ?? 'Tôi đã tới'),
            onPressed: () async {
              try {
                await ref.read(planRepositoryProvider).checkInArrived(planId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.safetyArrivedOk ?? 'Đã ghi nhận bạn đã tới',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.safetyArrivedError ?? 'Không ghi nhận được',
                      ),
                    ),
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
