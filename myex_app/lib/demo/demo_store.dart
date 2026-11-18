import 'package:flutter/foundation.dart';

import '../features/coach/domain/chat_message.dart';
import '../features/coach/domain/chat_origin.dart';
import '../features/draft_jail/domain/draft.dart';
import '../features/monetization/domain/paywall_offer.dart';
import '../features/monetization/domain/premium_state.dart';

/// DEMO MODE ONLY. In-memory stand-in for Supabase + RevenueCat state so the
/// whole app can be tried on a phone without any keys. Nothing persists
/// across launches except what the app itself keeps in SharedPreferences.
enum DemoTier { free, trial, monthly, annual }

class DemoStore extends ChangeNotifier {
  // ---- Entitlement ----
  DemoTier tier = DemoTier.free;
  bool willRenew = true;
  bool billingIssue = false;
  DateTime? expiresAt;
  bool hadTrial = false;
  bool hadIntro = false;
  bool bonusCreditedThisMonth = false;
  bool exitOfferShown = false;
  bool winbackShown = false;
  bool winbackEligible = false;
  PaywallVariant variant = PaywallVariant.timeline;

  // ---- Coins + limits (one demo "usage day") ----
  int coins = 20;
  int messagesUsed = 0;
  int messageCredits = 0;
  int draftsUsed = 0;
  final Set<int> unlockedDays = {};
  final Set<String> spentKeys = {};

  // ---- Product data ----
  final Map<int, (DateTime, List<String>)> planCompletions = {};
  final List<LockedDraft> drafts = [];
  final Map<String, ChatOrigin> conversations = {};
  final Map<String, List<ChatMessage>> messages = {};
  DateTime? noContactSince;
  int talks = 0;

  static const freeMessages = 3;
  static const freeDrafts = 1;
  static const bonusCoins = 50;

  bool get isPremium => tier != DemoTier.free && !_expired;
  bool get _expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  PremiumState get premium {
    if (!isPremium) return const PremiumState.free();
    return PremiumState(
      isActive: true,
      isTrial: tier == DemoTier.trial,
      willRenew: willRenew,
      expiresAt: expiresAt,
      billingIssue: billingIssue,
      productId: switch (tier) {
        DemoTier.monthly => 'myex_premium_monthly',
        _ => 'myex_premium_annual',
      },
    );
  }

  /// Next 09:00 local (the daily reset).
  DateTime get resetsAt {
    final n = DateTime.now();
    final today9 = DateTime(n.year, n.month, n.day, 9);
    return n.isBefore(today9) ? today9 : today9.add(const Duration(days: 1));
  }

  void setTier(DemoTier t) {
    tier = t;
    willRenew = true;
    final now = DateTime.now();
    expiresAt = switch (t) {
      DemoTier.free => null,
      DemoTier.trial => now.add(const Duration(days: 7)),
      DemoTier.monthly => DateTime(now.year, now.month + 1, now.day, now.hour),
      DemoTier.annual => DateTime(now.year + 1, now.month, now.day, now.hour),
    };
    if (t == DemoTier.trial) hadTrial = true;
    if (t != DemoTier.free && !bonusCreditedThisMonth) {
      coins += bonusCoins;
      bonusCreditedThisMonth = true;
    }
    notifyListeners();
  }

  void toggleWillRenew() {
    willRenew = !willRenew;
    notifyListeners();
  }

  void toggleBillingIssue() {
    billingIssue = !billingIssue;
    notifyListeners();
  }

  void addCoins(int n) {
    coins += n;
    notifyListeners();
  }

  /// Simulates Premium lapsing ~10 days ago → eligible for win-back.
  void simulateLapse() {
    tier = DemoTier.free;
    expiresAt = null;
    winbackEligible = true;
    winbackShown = false;
    notifyListeners();
  }

  /// "Tomorrow": the daily limits reset and the next plan day can open.
  /// Implemented by moving every timestamp one day into the past.
  void nextDay() {
    const d = Duration(days: 1);
    for (final k in planCompletions.keys.toList()) {
      final (at, e) = planCompletions[k]!;
      planCompletions[k] = (at.subtract(d), e);
    }
    for (var i = 0; i < drafts.length; i++) {
      final x = drafts[i];
      drafts[i] = LockedDraft(
        id: x.id,
        body: x.body,
        origin: x.origin,
        createdAt: x.createdAt.subtract(d),
        lockedUntil: x.lockedUntil.subtract(d),
        releasedAt: x.releasedAt,
      );
    }
    if (noContactSince != null) noContactSince = noContactSince!.subtract(d);
    if (expiresAt != null && tier != DemoTier.free) {
      expiresAt = expiresAt!.subtract(d);
    }
    messagesUsed = 0;
    draftsUsed = 0;
    notifyListeners();
  }

  void reset() {
    tier = DemoTier.free;
    willRenew = true;
    billingIssue = false;
    expiresAt = null;
    hadTrial = false;
    hadIntro = false;
    bonusCreditedThisMonth = false;
    exitOfferShown = false;
    winbackShown = false;
    winbackEligible = false;
    coins = 20;
    messagesUsed = 0;
    messageCredits = 0;
    draftsUsed = 0;
    unlockedDays.clear();
    spentKeys.clear();
    planCompletions.clear();
    drafts.clear();
    conversations.clear();
    messages.clear();
    noContactSince = null;
    talks = 0;
    notifyListeners();
  }

  void changed() => notifyListeners();
}
