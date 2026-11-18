import 'package:flutter/foundation.dart';

enum CoinPackTag { none, popular, bestValue }

/// A consumable coin pack. `coins`/`bonus` come from `public.coin_packs`
/// (the same table the webhook uses to credit); the price only from StoreKit.
@immutable
class CoinPack {
  const CoinPack({
    required this.productId,
    required this.coins,
    required this.bonus,
    required this.priceString,
    this.tag = CoinPackTag.none,
    this.handle,
  });

  final String productId;
  final int coins;
  final int bonus;
  final String priceString;
  final CoinPackTag tag;
  final Object? handle;

  int get total => coins + bonus;
}

/// A server-priced item that coins can buy (`public.coin_catalog`).
@immutable
class CoinCatalogItem {
  const CoinCatalogItem({
    required this.item,
    required this.cost,
    required this.grantQty,
  });

  factory CoinCatalogItem.fromJson(Map<String, dynamic> json) =>
      CoinCatalogItem(
        item: json['item'] as String,
        cost: (json['cost'] as num).toInt(),
        grantQty: (json['grant_qty'] as num?)?.toInt() ?? 1,
      );

  final String item;
  final int cost;
  final int grantQty;
}

/// Result of the `spend_coins` RPC.
sealed class SpendResult {
  const SpendResult();

  factory SpendResult.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final balance = (json['balance'] as num?)?.toInt();
    if (ok) {
      if (json['already_unlocked'] == true) return const SpendAlreadyUnlocked();
      return SpendOk(balance: balance ?? 0, replayed: json['replayed'] == true);
    }
    return switch (json['reason']) {
      'insufficient' => SpendInsufficient(
        balance: balance ?? 0,
        cost: (json['cost'] as num?)?.toInt() ?? 0,
      ),
      'premium_has_access' => const SpendPremiumHasAccess(),
      final Object? other => SpendRejected(other?.toString() ?? 'unknown'),
    };
  }
}

class SpendOk extends SpendResult {
  const SpendOk({required this.balance, this.replayed = false});
  final int balance;
  final bool replayed;
}

class SpendAlreadyUnlocked extends SpendResult {
  const SpendAlreadyUnlocked();
}

class SpendInsufficient extends SpendResult {
  const SpendInsufficient({required this.balance, required this.cost});
  final int balance;
  final int cost;
  int get missing => cost - balance;
}

class SpendPremiumHasAccess extends SpendResult {
  const SpendPremiumHasAccess();
}

class SpendRejected extends SpendResult {
  const SpendRejected(this.reason);
  final String reason;
}
