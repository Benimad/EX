import '../../monetization/domain/monetization_ids.dart';

/// Wire values match cancel_survey_responses.reason (M2 CHECK constraint).
enum CancelReason { price, better, unused, other }

/// What the survey offers for a reason (M8). Pure, unit tested.
sealed class CancelOffer {
  const CancelOffer();
  String? get wire => null;
}

/// Annual subscriber + "save50_annual" promo exists: half price for a year.
class Save50Offer extends CancelOffer {
  const Save50Offer();
  @override
  String get wire => MonetizationIds.promoSave50Annual;
}

/// Monthly subscriber: switch to yearly with the real savings %.
class SwitchToYearlyOffer extends CancelOffer {
  const SwitchToYearlyOffer(this.savingsPct);
  final int savingsPct;
  @override
  String get wire => 'switch_yearly';
}

/// "I'm not using it": a gentle nightly check-in (local notification).
class CheckinOffer extends CancelOffer {
  const CheckinOffer();
  @override
  String get wire => 'nightly_checkin';
}

/// "I'm feeling better": celebrate, no offer.
class CelebrateNoOffer extends CancelOffer {
  const CelebrateNoOffer();
}

/// "Something else" (or no applicable offer): thanks + optional note.
class ThanksNoOffer extends CancelOffer {
  const ThanksNoOffer();
}

abstract final class CancelSurvey {
  static CancelOffer offerFor(
    CancelReason reason, {
    required String? productId,
    required bool save50Available,
    required int? yearlySavingsPct,
  }) {
    switch (reason) {
      case CancelReason.price:
        final annual =
            productId == MonetizationIds.annual ||
            productId == MonetizationIds.annualIntroExit;
        if (annual && save50Available) return const Save50Offer();
        if (productId == MonetizationIds.monthly &&
            yearlySavingsPct != null &&
            yearlySavingsPct > 0) {
          return SwitchToYearlyOffer(yearlySavingsPct);
        }
        // Never the intro product: current subscribers aren't eligible.
        return const ThanksNoOffer();
      case CancelReason.better:
        return const CelebrateNoOffer();
      case CancelReason.unused:
        return const CheckinOffer();
      case CancelReason.other:
        return const ThanksNoOffer();
    }
  }
}
