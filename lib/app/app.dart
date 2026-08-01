import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/push/push_registrar.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/billing/application/iap_controller.dart';
import 'deep_link.dart';
import 'router.dart';

class CungHatApp extends ConsumerStatefulWidget {
  const CungHatApp({super.key});
  @override
  ConsumerState<CungHatApp> createState() => _CungHatAppState();
}

class _CungHatAppState extends ConsumerState<CungHatApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    // [AUDIT C1] purchaseStream phải có listener TRƯỚC khi user mua và ngay
    // khi app mở lại (store replay transaction treo) — không init thì user
    // trả tiền mà entitlement không bao giờ được cấp. init() tự nuốt lỗi
    // platform channel nên an toàn trên dev/test.
    unawaited(ref.read(iapControllerProvider).init());
  }

  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
      _linkSub = appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
    } catch (_) {
      // app_links uses platform channels; never crash the app over a bad/absent link.
    }
  }

  void _handleUri(Uri uri) {
    try {
      final location = deepLinkLocation(uri);
      if (location != null) ref.read(goRouterProvider).go(location);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  /// [DARK] User đổi dark/light ở CÀI ĐẶT MÁY trong lúc app đang chạy —
  /// đẩy vào provider để effectiveBrightness (mode system) tính lại.
  @override
  void didChangePlatformBrightness() {
    ref.read(platformBrightnessProvider.notifier).state =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    // [AUDIT P1-3] Đăng ký token FCM khi user CÓ hồ sơ (đã đăng nhập + qua
    // onboarding) — không phải lúc mở app ở màn đăng nhập, khi chưa có session
    // để gắn token vào.
    ref.watch(pushRegistrationProvider);
    // [DARK] Chọn bảng màu TRƯỚC khi dựng cây widget: mọi AppColors.x đọc
    // sau dòng này đều ra đúng bảng. themeMode đổi → build() chạy lại →
    // select() chạy lại → cây dưới MaterialApp rebuild với màu mới.
    AppColors.select(ref.watch(effectiveBrightnessProvider));
    return MaterialApp.router(
      title: 'Cùng Hát',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // [LANG] App phục vụ thị trường VN → MẶC ĐỊNH tiếng Việt bất kể ngôn
      // ngữ máy (UI review 2026-07-16: máy EN thấy giao diện trộn Việt-Anh).
      // User vẫn đổi được trong Cài đặt (override 'en'/'vi' persist).
      locale: ref.watch(localeControllerProvider) ?? const Locale('vi'),
      // [L10N] Chỉ còn chạy nếu locale trên trả null (không xảy ra nữa) —
      // giữ làm lưới an toàn: thứ tiếng ngoài supportedLocales → tiếng Việt.
      localeResolutionCallback: (device, supported) {
        for (final s in supported) {
          if (device?.languageCode == s.languageCode) return s;
        }
        return const Locale('vi');
      },
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
