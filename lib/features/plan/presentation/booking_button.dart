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
    this.amountMinor = 200000,
  });

  final String planId;
  final String venueId;
  final int amountMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.event_seat),
      label: Text(l10n?.bookVenue ?? 'Đặt phòng & giữ chỗ'),
      onPressed: () async {
        try {
          final url = await ref.read(planRepositoryProvider).startVenuePayment(
              planId: planId, venueId: venueId, amountMinor: amountMinor, gateway: 'momo');
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không tạo được thanh toán')));
          }
        }
      },
    );
  }
}
