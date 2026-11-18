import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../core/util/context_x.dart';
import '../domain/paywall_offer.dart';
import '../domain/price_format.dart';
import '../domain/purchase_outcome.dart';

/// Discount % of the exit offer vs the regular annual price, or null when
/// the offer can't be described truthfully (then it is never shown).
int? exitOfferDiscountPct(ExitOffer offer) {
  final intro = offer.plan.intro;
  if (intro == null) return null;
  return PriceFormat.discountPercent(
    introPrice: intro.price,
    regularPrice: offer.regularAnnual.price,
  );
}

// TODO(founder): research R6 suggests keeping the free trial in the exit
// offer: a separate `myex_premium_annual_offer` ($29.99/year with a 7-day
// trial, same subscription group), copy "Still free to try, for less."
// Not implemented on purpose (it's a new paid product). See README
// "Decisions pending". The current pay-up-front intro offer stays.
/// One-time exit offer (spec P4). No mascot, no eyebrow, no urgency copy.
/// The server flag still guarantees it is shown at most once.
/// Returns the purchase outcome, or null if dismissed.
Future<PurchaseOutcome?> showExitOfferSheet({
  required BuildContext context,
  required ExitOffer offer,
  required Future<PurchaseOutcome> Function() onClaim,
}) {
  final intro = offer.plan.intro;
  final pct = exitOfferDiscountPct(offer);
  // Never present an offer we can't describe truthfully.
  if (intro == null || pct == null) return Future.value();
  final l = context.l10n;
  // "Half price" only when it really is ~50%; otherwise the exact percent.
  final title = (pct >= 48 && pct <= 52)
      ? l.exitTitleHalf
      : l.exitTitlePct(PriceFormat(l.localeName).percent(pct));

  return showGlassSheet<PurchaseOutcome>(
    context: context,
    semanticLabel: l.exitSheetLabel,
    builder: (_) => _ExitOfferBody(
      title: title,
      offerPrice: intro.priceString,
      annualPrice: offer.regularAnnual.priceString,
      onClaim: onClaim,
    ),
  );
}

class _ExitOfferBody extends StatefulWidget {
  const _ExitOfferBody({
    required this.title,
    required this.offerPrice,
    required this.annualPrice,
    required this.onClaim,
  });

  final String title;
  final String offerPrice;
  final String annualPrice;
  final Future<PurchaseOutcome> Function() onClaim;

  @override
  State<_ExitOfferBody> createState() => _ExitOfferBodyState();
}

class _ExitOfferBodyState extends State<_ExitOfferBody> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final outcome = await widget.onClaim();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome is PurchaseCancelled) return; // stay on the sheet
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(MyExSpacing.s2),
        DisplayText(widget.title, size: MyExType.displaySheet),
        const Gap(MyExSpacing.s2),
        Text(
          l.exitBody(widget.offerPrice, widget.annualPrice),
          style: MyExType.body.copyWith(color: MyExColors.ink2),
          textAlign: TextAlign.center,
        ),
        const Gap(MyExSpacing.s6),
        PrimaryButton(
          label: l.exitCta(widget.offerPrice),
          busy: _busy,
          onPressed: _claim,
        ),
        TextLinkButton(
          label: l.commonNotNow,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        const Gap(MyExSpacing.s2),
        Footnote(l.paywallFineLegal),
      ],
    );
  }
}
