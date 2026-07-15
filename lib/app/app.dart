import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/billing/application/iap_controller.dart';
import 'deep_link.dart';
import 'router.dart';

class CungHatApp extends ConsumerStatefulWidget {
  const CungHatApp({super.key});
  @override
  ConsumerState<CungHatApp> createState() => _CungHatAppState();
}

class _CungHatAppState extends ConsumerState<CungHatApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
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
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cùng Hát',
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // [L10N] Song ngữ: theo ngôn ngữ máy; máy đặt thứ tiếng ngoài
      // supportedLocales → rơi về tiếng Việt (thị trường chính).
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
