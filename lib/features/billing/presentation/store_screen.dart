import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/billing_providers.dart';
import '../application/iap_controller.dart';
import '../domain/store_product.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final productsAsync = ref.watch(storeProductsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.storeTitle ?? 'Nang cap')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(storeProductsProvider),
            child: const Text('Thu lai'),
          ),
        ),
        data: (products) {
          final pro = products.where((p) => p.isPro).toList();
          final boosts = products.where((p) => p.isBoost).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (pro.isNotEmpty) ...[
                Text('Pro', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final product in pro) _ProductCard(product: product),
                const SizedBox(height: 20),
              ],
              if (boosts.isNotEmpty) ...[
                Text('Day keo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final product in boosts) _ProductCard(product: product),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(product),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (product.badge != null) _Badge(label: _badge(product.badge!)),
              ],
            ),
            const SizedBox(height: 6),
            Text(_description(product)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () =>
                    ref.read(iapControllerProvider).buyProduct(product),
                child: Text(_price(product)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(StoreProduct product) {
    if (product.isBoost) {
      return product.boostCredits > 1
          ? '${product.boostCredits} luot day'
          : 'Day keo 24h';
    }
    switch (product.billingPeriod) {
      case 'monthly':
        return 'Pro hang thang';
      case 'yearly':
        return 'Pro hang nam';
      case 'lifetime':
        return 'Pro tron doi';
      default:
        return 'Pro';
    }
  }

  String _description(StoreProduct product) {
    if (product.isBoost) {
      return 'Day mot keo dang mo len dau bang trong 24 gio.';
    }
    if (product.billingPeriod == 'lifetime') {
      return 'Uu dai launch co the bien mat khi du so paid Pro users.';
    }
    return 'Tao keo, tham gia nhieu keo, bo loc nang cao, xem ai thich ban va 1 luot day moi thang.';
  }

  String _price(StoreProduct product) {
    switch (product.billingPeriod) {
      case 'monthly':
        return '${product.priceLabel} / thang';
      case 'yearly':
        return '${product.priceLabel} / nam';
      case 'lifetime':
        return '${product.priceLabel} tron doi';
      default:
        return product.priceLabel;
    }
  }

  String _badge(String badge) {
    switch (badge) {
      case 'best_value':
        return 'Loi nhat';
      case 'launch':
        return 'Launch';
      case 'ending_soon':
        return 'Sap ket thuc';
      default:
        return badge;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
