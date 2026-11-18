import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/purchases_repository.dart';
import '../data/wallet_repository.dart';
import '../domain/coin_pack.dart';
import '../domain/limits.dart';
import '../domain/paywall_offer.dart';
import '../domain/premium_state.dart';
import 'revenuecat_bootstrap.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(supabaseClientProvider)),
);

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  final wallet = ref.watch(walletRepositoryProvider);
  return RevenueCatPurchasesRepository(
    serverSync: wallet.syncPurchases,
    storeAvailable: RevenueCatBootstrap.isSupportedPlatform,
  );
});

/// Display-only entitlement (CustomerInfo listener). Server decides unlocks.
final premiumProvider = StreamProvider<PremiumState>((ref) {
  ref.watch(authUserIdProvider);
  return ref.watch(purchasesRepositoryProvider).premiumStream();
});

/// Convenience: premium or not (false while loading).
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(premiumProvider).value?.isActive ?? false,
);

final paywallOfferProvider = FutureProvider.autoDispose<PaywallOffer>(
  (ref) => ref.watch(purchasesRepositoryProvider).getPaywall(),
);

final coinBalanceProvider = StreamProvider<int>((ref) {
  ref.watch(authUserIdProvider);
  return ref.watch(walletRepositoryProvider).balanceStream();
});

final limitsProvider = FutureProvider.autoDispose<LimitsState>((ref) {
  ref.watch(authUserIdProvider);
  return ref.watch(walletRepositoryProvider).fetchLimits();
});

final coinCatalogProvider = FutureProvider<Map<String, CoinCatalogItem>>(
  (ref) => ref.watch(walletRepositoryProvider).fetchCatalog(),
);

final coinPacksProvider = FutureProvider.autoDispose<List<CoinPack>>((
  ref,
) async {
  final defs = await ref.watch(walletRepositoryProvider).fetchCoinPacks();
  return ref.watch(purchasesRepositoryProvider).getCoinPacks(defs);
});

/// Call after any purchase, restore or spend.
void invalidateMonetization(WidgetRef ref) {
  ref
    ..invalidate(limitsProvider)
    ..invalidate(coinBalanceProvider)
    ..invalidate(premiumProvider);
}
