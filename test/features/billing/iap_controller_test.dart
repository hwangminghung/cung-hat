import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/application/iap_controller.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';

class _MockIap extends Mock implements InAppPurchase {}

class _MockBillingRepo extends Mock implements BillingRepository {}

PurchaseDetails _purchased(String productId) => PurchaseDetails(
  purchaseID: 'txn-1',
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'receipt-data',
    source: 'google_play',
  ),
  transactionDate: '0',
  status: PurchaseStatus.purchased,
);

void main() {
  late _MockIap iap;
  late _MockBillingRepo repo;
  late StreamController<List<PurchaseDetails>> purchases;
  late ProviderContainer container;
  late IapController controller;

  setUp(() {
    iap = _MockIap();
    repo = _MockBillingRepo();
    purchases = StreamController<List<PurchaseDetails>>();
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => iap.purchaseStream).thenAnswer((_) => purchases.stream);
    when(() => repo.myEntitlements()).thenAnswer((_) async => []);
    when(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: any(named: 'storeProductId'),
        storeTxnId: any(named: 'storeTxnId'),
        receipt: any(named: 'receipt'),
      ),
    ).thenAnswer((_) async {});
    final p = Provider((ref) => IapController(ref, iap: iap));
    container = ProviderContainer(
      overrides: [billingRepositoryProvider.overrideWithValue(repo)],
    );
    controller = container.read(p);
  });

  tearDown(() {
    // KHÔNG await close(): future của close chỉ hoàn thành khi listener nhận
    // done — test `buy` không gọi init() nên stream không có listener, await
    // sẽ treo tới timeout.
    unawaited(purchases.close());
    container.dispose();
  });

  // [AUDIT C1] Trước đây init() không được gọi ở đâu cả: purchaseStream không
  // có listener → user trả tiền nhưng validate-iap không bao giờ chạy,
  // entitlement không được cấp. Các test này khoá hành vi của init().
  test('init nghe purchaseStream: purchase đến → deliverPurchase', () async {
    await controller.init();
    purchases.add([_purchased('pro')]);
    await pumpEventQueue();
    verify(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: 'pro',
        storeTxnId: 'txn-1',
        receipt: 'receipt-data',
      ),
    ).called(1);
  });

  test('init idempotent: gọi 2 lần không double-listen/không throw', () async {
    await controller.init();
    // purchaseStream là single-subscription: listen lần 2 sẽ throw nếu thiếu
    // guard — init lần 2 phải là no-op.
    await controller.init();
    purchases.add([_purchased('pro')]);
    await pumpEventQueue();
    verify(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: any(named: 'storeProductId'),
        storeTxnId: any(named: 'storeTxnId'),
        receipt: any(named: 'receipt'),
      ),
    ).called(1);
  });

  test('buy trả false khi catalog fail (UI có tín hiệu báo lỗi)', () async {
    when(() => repo.storeProductIds(any())).thenThrow(StateError('net'));
    expect(await controller.buy('pro'), isFalse);
  });

  // [AUDIT P1-1] init() ĐÁNH DẤU đã khởi tạo TRƯỚC khi isAvailable() thành
  // công: một lỗi tạm thời (offline lúc mở app, platform channel chưa sẵn
  // sàng) khoá vĩnh viễn purchaseStream — user trả tiền, entitlement không
  // bao giờ tới. Chỉ được coi là khởi tạo xong KHI listener đã gắn.
  group('init phải thử lại được sau lỗi tạm thời', () {
    test('isAvailable throw lần đầu → init lần sau vẫn gắn listener', () async {
      when(() => iap.isAvailable()).thenThrow(StateError('channel chưa sẵn'));
      await controller.init();

      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      await controller.init();

      purchases.add([_purchased('pro')]);
      await pumpEventQueue();
      verify(
        () => repo.deliverPurchase(
          platform: any(named: 'platform'),
          storeProductId: 'pro',
          storeTxnId: 'txn-1',
          receipt: 'receipt-data',
        ),
      ).called(1);
    });

    test('isAvailable=false lần đầu → init lần sau vẫn gắn listener', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      await controller.init();

      when(() => iap.isAvailable()).thenAnswer((_) async => true);
      await controller.init();

      purchases.add([_purchased('pro')]);
      await pumpEventQueue();
      verify(
        () => repo.deliverPurchase(
          platform: any(named: 'platform'),
          storeProductId: 'pro',
          storeTxnId: 'txn-1',
          receipt: 'receipt-data',
        ),
      ).called(1);
    });

    test(
      'hai init song song không double-listen (stream single-sub)',
      () async {
        await Future.wait([controller.init(), controller.init()]);
        purchases.add([_purchased('pro')]);
        await pumpEventQueue();
        verify(
          () => repo.deliverPurchase(
            platform: any(named: 'platform'),
            storeProductId: any(named: 'storeProductId'),
            storeTxnId: any(named: 'storeTxnId'),
            receipt: any(named: 'receipt'),
          ),
        ).called(1);
      },
    );
  });

  // [AUDIT P1-1] Nếu init lúc mở app thất bại, nút Mua vẫn phải tự dựng lại
  // listener — nếu không, luồng mua chạy mà kết quả không ai nhận.
  test('buy tự gắn listener khi init lúc mở app đã thất bại', () async {
    when(() => iap.isAvailable()).thenThrow(StateError('offline'));
    await controller.init();

    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => repo.storeProductIds(any())).thenAnswer((_) async => {});
    await controller.buy(
      'pro',
    ); // catalog rỗng → false, nhưng listener phải gắn

    purchases.add([_purchased('pro')]);
    await pumpEventQueue();
    verify(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: 'pro',
        storeTxnId: 'txn-1',
        receipt: 'receipt-data',
      ),
    ).called(1);
  });
}
