import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/monetization/domain/purchase_outcome.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('mapPurchasesErrorCode', () {
    test('cancel is silent, pending is Ask to Buy, owned is restore', () {
      expect(
        mapPurchasesErrorCode(PurchasesErrorCode.purchaseCancelledError),
        isA<PurchaseCancelled>(),
      );
      expect(
        mapPurchasesErrorCode(PurchasesErrorCode.paymentPendingError),
        isA<PurchasePending>(),
      );
      expect(
        mapPurchasesErrorCode(PurchasesErrorCode.productAlreadyPurchasedError),
        isA<PurchaseAlreadyOwned>(),
      );
    });

    test('everything else is a failure with the code name', () {
      final o = mapPurchasesErrorCode(PurchasesErrorCode.networkError, 'x');
      expect(o, isA<PurchaseFailed>());
      expect((o as PurchaseFailed).code, 'networkError');
    });

    test('PlatformException codes from the SDK map through the helper', () {
      final e = PlatformException(
        code: '${PurchasesErrorCode.purchaseCancelledError.index}',
      );
      expect(
        mapPurchasesErrorCode(PurchasesErrorHelper.getErrorCode(e)),
        isA<PurchaseCancelled>(),
      );
    });
  });

  group('trial eligibility', () {
    test('only explicit eligible + zero-price intro counts', () {
      expect(
        mapTrialEligibility(
          status: IntroEligibilityStatus.introEligibilityStatusEligible,
          introPrice: 0,
        ),
        isTrue,
      );
      expect(
        mapTrialEligibility(
          status: IntroEligibilityStatus.introEligibilityStatusUnknown,
          introPrice: 0,
        ),
        isFalse,
        reason: 'unknown must never say "free"',
      );
      expect(
        mapTrialEligibility(
          status: IntroEligibilityStatus.introEligibilityStatusIneligible,
          introPrice: 0,
        ),
        isFalse,
      );
      expect(
        mapTrialEligibility(
          status: IntroEligibilityStatus.introEligibilityStatusEligible,
          introPrice: 24.99,
        ),
        isFalse,
      );
      expect(
        mapTrialEligibility(
          status: IntroEligibilityStatus.introEligibilityStatusEligible,
          introPrice: null,
        ),
        isFalse,
      );
    });
  });
}
