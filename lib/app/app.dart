import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
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
      // cunghat://plan/<token>
      if (uri.scheme == 'cunghat' &&
          uri.host == 'plan' &&
          uri.pathSegments.isNotEmpty) {
        final token = uri.pathSegments.first;
        ref.read(goRouterProvider).go('/plan/shared/$token');
      }
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
      locale: const Locale('vi'),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
