import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/iap_controller.dart';

/// One purchasable upgrade row. Rendered statically — no provider read at build.
class _Upgrade {
  const _Upgrade(this.feature, this.title, this.description);
  final String feature;
  final String title;
  final String description;
}

const _upgrades = <_Upgrade>[
  _Upgrade('boost', 'Đẩy kèo lên top', 'Đẩy kèo của bạn lên đầu bảng 24 giờ'),
  _Upgrade('see_likes', 'Xem ai đã thích bạn', 'Mở khoá danh sách người đã thích bạn'),
  _Upgrade('premium_filters', 'Bộ lọc nâng cao', 'Lọc theo gu nhạc, độ tuổi, khu vực'),
];

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.storeTitle ?? 'Nâng cấp')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final u in _upgrades)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleFor(l10n, u),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(u.description),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => ref.read(iapControllerProvider).buy(u.feature),
                        child: Text(l10n?.buy ?? 'Mua'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _titleFor(AppLocalizations? l10n, _Upgrade u) {
    switch (u.feature) {
      case 'boost':
        return l10n?.boostTitle ?? 'Đẩy kèo lên top';
      case 'see_likes':
        return l10n?.seeLikesTitle ?? 'Xem ai đã thích bạn';
      case 'premium_filters':
        return l10n?.filtersTitle ?? 'Bộ lọc nâng cao';
      default:
        return u.title;
    }
  }
}
