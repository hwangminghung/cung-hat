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
    // [UI-AUDIT] Hàng action PHỤ đồng cỡ dưới CTA chính: OutlinedButton cùng
    // kiểu + label ngắn ("Chia sẻ" thay vì "Chia sẻ cho bạn bè" từng xuống 3
    // dòng ở 360dp). Câu đầy đủ vẫn nằm trong share message.
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text(
              l10n?.safetyShareShort ?? 'Chia sẻ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
          child: OutlinedButton.icon(
            key: const Key('checkin_btn'),
            icon: const Icon(Icons.place, size: 18),
            label: Text(
              l10n?.safetyArrived ?? 'Tôi đã tới',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
