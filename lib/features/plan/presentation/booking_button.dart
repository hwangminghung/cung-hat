import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/plan_providers.dart';

class BookingButton extends ConsumerWidget {
  const BookingButton({
    super.key,
    required this.planId,
    required this.venueId,
  });

  final String planId;
  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.event_seat),
      label: Text(l10n?.bookVenue ?? 'Đặt phòng & giữ chỗ'),
      onPressed: () async {
        final gateway = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('booking_gw_momo'),
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('MoMo'),
                  onTap: () => Navigator.pop(ctx, 'momo'),
                ),
                ListTile(
                  key: const Key('booking_gw_zalopay'),
                  leading: const Icon(Icons.payment),
                  title: const Text('ZaloPay'),
                  onTap: () => Navigator.pop(ctx, 'zalopay'),
                ),
              ],
            ),
          ),
        );
        if (gateway == null || !context.mounted) return;
        try {
          final url = await ref.read(planRepositoryProvider).startVenuePayment(
              planId: planId, venueId: venueId, gateway: gateway);
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          if (context.mounted) {
            final msg = e.toString().contains('not_configured')
                ? 'Cổng thanh toán chưa được cấu hình'
                : 'Không tạo được thanh toán';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      },
    );
  }
}
