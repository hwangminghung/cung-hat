import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/plan_providers.dart';

class BookingButton extends ConsumerStatefulWidget {
  const BookingButton({super.key, required this.planId, required this.venueId});

  final String planId;
  final String venueId;

  @override
  ConsumerState<BookingButton> createState() => _BookingButtonState();
}

class _BookingButtonState extends ConsumerState<BookingButton> {
  /// True while a payment request is in flight. Blocks re-entry (double-tap
  /// would double-fire the payment) and disables the button until cleared.
  bool _busy = false;

  Future<void> _startBooking() async {
    if (_busy) return;
    final gateway = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        key: const Key('screen_20_booking_payment'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  Localizations.of<AppLocalizations>(
                        ctx,
                        AppLocalizations,
                      )?.bookingPickGateway ??
                      'Chọn cổng thanh toán',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
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
    if (gateway == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(planRepositoryProvider)
          .startVenuePayment(
            planId: widget.planId,
            venueId: widget.venueId,
            gateway: gateway,
          );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        final msg = e.toString().contains('not_configured')
            ? (l10n?.bookingNotConfigured ??
                  'Cổng thanh toán chưa được cấu hình')
            : (l10n?.bookingCreateError ?? 'Không tạo được thanh toán');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return FilledButton.tonalIcon(
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.event_seat),
      label: Text(l10n?.bookVenue ?? 'Đặt phòng & giữ chỗ'),
      onPressed: _busy ? null : _startBooking,
    );
  }
}
