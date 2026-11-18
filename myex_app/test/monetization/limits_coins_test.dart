import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/coach/domain/chat_origin.dart';
import 'package:myex_app/features/monetization/domain/coin_pack.dart';
import 'package:myex_app/features/monetization/domain/limits.dart';

void main() {
  group('LimitsState / MeterState', () {
    final free = LimitsState.fromJson({
      'premium': false,
      'free_msgs_left': 2,
      'message_credits': 5,
      'drafts_left': 1,
      'resets_at': '2026-11-18T06:00:00+00:00',
    });

    test('parses get_limits()', () {
      expect(free.premium, isFalse);
      expect(free.freeMessagesLeft, 2);
      expect(free.messageCredits, 5);
      expect(free.resetsAt, DateTime.utc(2026, 11, 18, 6).toLocal());
    });

    test('free user, normal chat → meter visible with remaining dots', () {
      final m = MeterState.derive(origin: ChatOrigin.normal, limits: free);
      expect(m.visible, isTrue);
      expect(m.sosMode, isFalse);
      expect(m.total, 3);
      expect(m.filled, 2);
    });

    test('SOS chat → never a meter, even for a free user at the limit', () {
      final atLimit = LimitsState.fromJson({
        'premium': false,
        'free_msgs_left': 0,
      });
      final m = MeterState.derive(origin: ChatOrigin.sos, limits: atLimit);
      expect(m.visible, isFalse);
      expect(m.sosMode, isTrue);
    });

    test('premium → no meter', () {
      final m = MeterState.derive(
        origin: ChatOrigin.normal,
        limits: LimitsState.fromJson({'premium': true}),
      );
      expect(m.visible, isFalse);
    });

    test('filled is clamped to the total', () {
      final m = MeterState.derive(
        origin: ChatOrigin.normal,
        limits: LimitsState.fromJson({'premium': false, 'free_msgs_left': 9}),
      );
      expect(m.filled, 3);
    });
  });

  group('coins', () {
    test('canAfford', () {
      expect(canAfford(balance: 10, cost: 10), isTrue);
      expect(canAfford(balance: 9, cost: 10), isFalse);
      expect(canAfford(balance: -5, cost: 10), isFalse, reason: 'clawback');
      expect(canAfford(balance: 10, cost: 0), isFalse);
    });

    test('SpendResult.fromJson maps every RPC shape', () {
      expect(
        SpendResult.fromJson({'ok': true, 'balance': 5}),
        isA<SpendOk>().having((r) => r.balance, 'balance', 5),
      );
      expect(
        SpendResult.fromJson({'ok': true, 'replayed': true, 'balance': 5}),
        isA<SpendOk>().having((r) => r.replayed, 'replayed', isTrue),
      );
      expect(
        SpendResult.fromJson({'ok': true, 'already_unlocked': true}),
        isA<SpendAlreadyUnlocked>(),
      );
      expect(
        SpendResult.fromJson({
          'ok': false,
          'reason': 'insufficient',
          'balance': 4,
          'cost': 15,
        }),
        isA<SpendInsufficient>().having((r) => r.missing, 'missing', 11),
      );
      expect(
        SpendResult.fromJson({'ok': false, 'reason': 'premium_has_access'}),
        isA<SpendPremiumHasAccess>(),
      );
      expect(
        SpendResult.fromJson({'ok': false, 'reason': 'weird'}),
        isA<SpendRejected>(),
      );
    });

    test('CoinPack total includes the bonus', () {
      const p = CoinPack(
        productId: 'coins_80',
        coins: 80,
        bonus: 10,
        priceString: 'x',
      );
      expect(p.total, 90);
    });
  });
}
