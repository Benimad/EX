import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/util/context_x.dart';
import '../../application/monetization_providers.dart';

/// Coin balance chip → Coins. Glass, 36pt visual, tabular figures.
/// Never shown on SOS. (The Home "Premium" crown chip was removed in the
/// design pass: premium is shown as status in lists, not as a badge.)
class CoinChip extends ConsumerWidget {
  const CoinChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(coinBalanceProvider).value;
    return GlassChip(
      label: balance?.toString() ?? '–',
      leading: const CoinIcon(),
      semanticLabel: context.l10n.coinChipSemantics(balance ?? 0),
      onPressed: () => context.push(Routes.coins),
    );
  }
}
