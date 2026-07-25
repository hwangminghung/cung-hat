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
      // [AUDIT A2] Mac dinh sheet bi kep o 9/16 chieu cao man (360dp tren may
      // 640dp). Rieng doan planPayNote cao 209dp o 360dp/textScale 1.4, tong
      // noi dung ~410dp -> RenderFlex tran 50dp. isScrollControlled bo tran
      // 9/16, SingleChildScrollView lo not phan con lai o co chu lon hon.
      // Column van mainAxisSize.min nen o co chu thuong sheet khong cao them.
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        key: const Key('screen_20_booking_payment'),
        child: SingleChildScrollView(
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
              // [AUDIT A2] Noi ro app KHONG giu cho va KHONG xu ly hoan tien —
              // truoc day nhan nut hua "giu cho" ma luong nay khong he lam.
              // Dat DUOI 2 lua chon de khong day tap target xuong duoi man.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  Localizations.of<AppLocalizations>(
                        ctx,
                        AppLocalizations,
                      )?.planPayNote ??
                      'Thanh toán diễn ra trong ứng dụng MoMo hoặc ZaloPay. '
                          'Cùng Hát không giữ chỗ tại quán và không xử lý hoàn tiền.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            ],
          ),
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
      // [AUDIT A2] canLaunchUrl false truoc day khong lam gi ca: user bam
      // xong thi khong co gi xay ra va cung khong co bao loi. Xay ra that khi
      // may chua cai MoMo/ZaloPay.
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.planPayOpenError ??
                  'Không mở được ứng dụng thanh toán. Kiểm tra xem bạn đã cài '
                      'MoMo hoặc ZaloPay chưa.',
            ),
          ),
        );
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
          // [AUDIT A2] event_seat goi y "giu ghe" — luong nay khong giu gi ca.
          : const Icon(Icons.payments_outlined),
      // Fallback phai khop ARB: "giu cho" la loi hua app khong he thuc hien.
      label: Text(l10n?.bookVenue ?? 'Thanh toán tại quán qua MoMo/ZaloPay'),
      onPressed: _busy ? null : _startBooking,
    );
  }
}
