import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/coin_pack.dart';
import '../domain/limits.dart';
import '../domain/monetization_ids.dart';

/// Server-side wallet, limits and one-time flags. Reads are display-only;
/// every write that costs or unlocks goes through a SECURITY DEFINER RPC.
class WalletRepository {
  WalletRepository(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  /// Live coin balance: Supabase Realtime on `coin_wallets`, plus a slow poll
  /// as a fallback (Realtime may be disabled for the table or the socket may
  /// drop). Requires `coin_wallets` in the `supabase_realtime` publication.
  Stream<int> balanceStream({
    Duration pollEvery = const Duration(seconds: 30),
  }) {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    late final StreamController<int> controller;
    RealtimeChannel? channel;
    Timer? timer;

    Future<void> refresh() async {
      try {
        controller.add(await fetchBalance());
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        unawaited(refresh());
        channel = _db
            .channel('wallet:$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'coin_wallets',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: uid,
              ),
              callback: (payload) {
                final b = payload.newRecord['balance'];
                if (b is num) controller.add(b.toInt());
              },
            )
            .subscribe();
        timer = Timer.periodic(pollEvery, (_) => refresh());
      },
      onCancel: () async {
        timer?.cancel();
        final c = channel;
        if (c != null) await _db.removeChannel(c);
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<int> fetchBalance() async {
    final row = await _db.from('coin_wallets').select('balance').maybeSingle();
    return (row?['balance'] as num?)?.toInt() ?? 0;
  }

  /// Spend coins. [idempotencyKey] must be created ONCE per user intent and
  /// reused on retry (double taps spend once).
  Future<SpendResult> spend({
    required String item,
    required String ref,
    required String idempotencyKey,
  }) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      MonetizationIds.rpcSpendCoins,
      params: {
        'p_item': item,
        'p_ref': ref,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return SpendResult.fromJson(res);
  }

  Future<LimitsState> fetchLimits() async {
    final res = await _db.rpc<Map<String, dynamic>>(
      MonetizationIds.rpcGetLimits,
    );
    return LimitsState.fromJson(res);
  }

  Future<Map<String, CoinCatalogItem>> fetchCatalog() async {
    final rows = await _db.from('coin_catalog').select('item,cost,grant_qty');
    return {
      for (final r in rows) r['item'] as String: CoinCatalogItem.fromJson(r),
    };
  }

  Future<Map<String, ({int coins, int bonus})>> fetchCoinPacks() async {
    final rows = await _db.from('coin_packs').select('product_id,coins,bonus');
    return {
      for (final r in rows)
        r['product_id'] as String: (
          coins: (r['coins'] as num).toInt(),
          bonus: (r['bonus'] as num).toInt(),
        ),
    };
  }

  /// True only for the call that "wins" the right to show the exit offer.
  /// Server-enforced, once per user, ever.
  Future<bool> markExitOfferShown() async {
    final res = await _db.rpc<bool>(MonetizationIds.rpcMarkExitOfferShown);
    return res;
  }

  /// Whether this month's premium bonus has landed in the ledger.
  Future<bool> premiumBonusCreditedThisMonth() async {
    final now = DateTime.now().toUtc();
    final monthStart = DateTime.utc(now.year, now.month);
    final rows = await _db
        .from('coin_ledger')
        .select('id')
        .eq('kind', 'premium_bonus')
        .gte('created_at', monthStart.toIso8601String())
        .limit(1);
    return rows.isNotEmpty;
  }

  /// Stores the paywall "remind me" choice server-side (M5/M7).
  Future<void> setRemindTrial(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('profiles').update({'remind_trial': value}).eq('id', uid);
  }

  Future<void> syncPurchases() async {
    await _db.functions.invoke(MonetizationIds.fnSyncPurchases);
  }
}
