import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/billing_repository.dart';
import 'billing_providers.dart';

/// Features sold as consumables (re-buyable); everything else is non-consumable.
const _consumables = <String>{'boost'};

/// Ket qua cua mot vong giao dich. UI listen de phan hoi thay vi im lang.
///
/// [AUDIT P1-b] Truoc day chi `purchased`/`restored` duoc xu ly: giao dich
/// pending/error/canceled roi vao khoang trong — user khong biet chuyen gi
/// xay ra, va giao dich loi khong bao gio duoc completePurchase nen store
/// phat lai moi lan mo app.
enum IapEvent { pending, success, restored, failed, canceled, deliveryFailed }

/// Su kien giao dich gan nhat (null = da tieu thu xong).
final iapEventProvider = StateProvider<IapEvent?>((ref) => null);

/// Gia localized LAY TRUC TIEP TU STORE, khoa theo `type`.
///
/// [AUDIT P1-a] Apple 3.1.2 va Google Play Payments yeu cau hien dung gia ma
/// store dang tinh cho user o quoc gia cua ho. Gia trong bang `products` chi
/// la fallback hien thi: sau khi doi gia tren App Store Connect / Play
/// Console, hai ben lech nhau va build co the bi tu choi.
///
/// Khong throw: khong hoi duoc store (offline, emulator, widget test) thi tra
/// map rong de UI rot ve gia catalog.
final storePricesProvider = FutureProvider<Map<String, String>>((ref) async {
  final catalog = await ref.watch(storeProductsProvider.future);
  return ref.read(iapControllerProvider).localizedPrices(catalog);
});

class IapController {
  IapController(this.ref, {InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  final Ref ref;
  final InAppPurchase _iap;
  Map<String, String>? _catalog;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Future<void>? _attaching;

  /// Call from app startup (NOT from the constructor) — touches platform
  /// channels. [AUDIT C1] Không gọi init thì purchaseStream không có listener:
  /// user trả tiền nhưng validate-iap không bao giờ chạy, entitlement không
  /// được cấp. Idempotent: purchaseStream là single-subscription, listen 2
  /// lần sẽ throw. Nuốt lỗi platform channel để dev/test không crash.
  ///
  /// [AUDIT P1-1] Cờ "đã init" trước đây được bật TRƯỚC khi isAvailable()
  /// thành công, nên một lỗi tạm thời (mở app lúc offline, platform channel
  /// chưa sẵn sàng) khoá listener VĨNH VIỄN cho cả vòng đời process: user trả
  /// tiền mà entitlement không bao giờ tới. Nay trạng thái nằm ở [_sub] —
  /// chỉ đặt sau khi listen() thành công — nên lần gọi sau tự phục hồi.
  Future<void> init() {
    if (_sub != null) return Future.value();
    // Hai lời gọi song song (startup + nút Mua) phải cùng chờ MỘT lần attach:
    // purchaseStream là single-subscription, listen 2 lần sẽ throw.
    return _attaching ??= _attach().whenComplete(() => _attaching = null);
  }

  Future<void> _attach() async {
    try {
      if (!await _iap.isAvailable()) return;
      _sub = _iap.purchaseStream.listen(_onPurchases);
    } catch (e) {
      // KHÔNG latch trạng thái lỗi: lần gọi sau được phép thử lại.
      debugPrint('IAP init skipped (sẽ thử lại lần sau): $e');
    }
  }

  /// Gỡ listener khi container bị dispose — tránh rò subscription trong test
  /// và khi ProviderScope bị dựng lại.
  Future<void> dispose() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
  }

  Future<String?> _productIdFor(String feature) async {
    try {
      _catalog ??= await ref
          .read(billingRepositoryProvider)
          .storeProductIds(
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          );
    } catch (e) {
      debugPrint('IAP catalog load failed: $e');
      return null;
    }
    return _catalog![feature];
  }

  /// Kick-off mua hàng. Trả false khi không mở được flow store (catalog lỗi,
  /// product không tồn tại, store throw) để UI báo user thay vì im lặng.
  ///
  /// Tra ve true CHI co nghia da mo duoc man thanh toan — ket qua that den sau
  /// qua purchaseStream, xem [_onPurchases].
  Future<bool> buy(String feature) async {
    // [AUDIT P1-1] Nếu init lúc mở app thất bại (offline), luồng mua vẫn phải
    // dựng lại listener TRƯỚC khi mở màn thanh toán — nếu không, giao dịch
    // hoàn tất mà không ai nhận kết quả để cấp entitlement.
    await init();
    final productId = await _productIdFor(feature);
    if (productId == null) return false;
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      if (_consumables.contains(feature)) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
      return true;
    } catch (e) {
      debugPrint('IAP buy failed for $feature: $e');
      return false;
    }
  }

  /// [AUDIT P1-b] Apple 3.1.1 BAT BUOC nut khoi phuc voi san pham
  /// non-consumable: user doi may hoac cai lai app phai lay lai duoc thu da
  /// mua ma khong tra tien lan hai. Thieu nut nay la ly do tu choi pho bien.
  ///
  /// Ket qua ve BAT DONG BO qua purchaseStream voi status `restored`, nen
  /// true o day chi co nghia da goi duoc store.
  Future<bool> restore() async {
    // Kết quả restore về QUA purchaseStream — không có listener thì bấm nút
    // xong không có gì xảy ra (Apple 3.1.1 sẽ đánh trượt).
    await init();
    try {
      if (!await _iap.isAvailable()) return false;
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('IAP restore failed: $e');
      return false;
    }
  }

  /// Gia localized cho tung `type`. Khong throw — loi tra map rong.
  Future<Map<String, String>> localizedPrices(
    List<StoreProduct> catalog,
  ) async {
    if (catalog.isEmpty) return const {};
    try {
      if (!await _iap.isAvailable()) return const {};
      final response = await _iap.queryProductDetails({
        for (final p in catalog) p.storeProductId,
      });
      final byId = {for (final d in response.productDetails) d.id: d.price};
      return {
        for (final p in catalog)
          if (byId[p.storeProductId] != null) p.type: byId[p.storeProductId]!,
      };
    } catch (e) {
      debugPrint('IAP price query failed: $e');
      return const {};
    }
  }

  void _emit(IapEvent event) {
    try {
      ref.read(iapEventProvider.notifier).state = event;
    } catch (e) {
      // Container da dispose (user thoat man hinh giua chung) — bo qua.
      debugPrint('IAP event dropped: $e');
    }
  }

  /// Bao store da xu ly xong giao dich. BAT BUOC voi moi trang thai ket thuc,
  /// ke ca error/canceled: khong goi thi store phat lai giao dich do moi lan
  /// mo app va user thay bao loi lap vo han.
  Future<void> _finish(PurchaseDetails pd) async {
    if (!pd.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(pd);
    } catch (e) {
      debugPrint('completePurchase failed for ${pd.productID}: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    for (final pd in purchases) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          // Vd thanh toan cho phe duyet (Ask to Buy, chuyen khoan) — co the
          // keo dai nhieu ngay. Chua completePurchase.
          _emit(IapEvent.pending);
        case PurchaseStatus.canceled:
          _emit(IapEvent.canceled);
          await _finish(pd);
        case PurchaseStatus.error:
          debugPrint('IAP purchase error for ${pd.productID}: ${pd.error}');
          _emit(IapEvent.failed);
          await _finish(pd);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await ref
                .read(billingRepositoryProvider)
                .deliverPurchase(
                  platform: platform,
                  storeProductId: pd.productID,
                  storeTxnId: pd.purchaseID ?? '',
                  receipt: pd.verificationData.serverVerificationData,
                );
            await _finish(pd);
            ref.invalidate(entitlementsProvider);
            _emit(
              pd.status == PurchaseStatus.restored
                  ? IapEvent.restored
                  : IapEvent.success,
            );
          } catch (e) {
            // KHONG complete purchase — de store phat lai o lan mo app sau,
            // nho vay tien da tra khong bi mat entitlement vinh vien.
            // TODO(prod): record/report this delivery failure.
            debugPrint('deliverPurchase failed for ${pd.productID}: $e');
            _emit(IapEvent.deliveryFailed);
          }
      }
    }
  }
}

final iapControllerProvider = Provider((ref) {
  final controller = IapController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
