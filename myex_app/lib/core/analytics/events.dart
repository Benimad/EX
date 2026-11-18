/// Every analytics event in the funnel (M9). Feature code never passes
/// free-form event names: it calls typed methods on `Analytics`.
///
/// [allowedProps] is an allowlist. Anything else is dropped before it reaches
/// a sink, so chat, journal, draft or plan text can never leak into analytics
/// (test/analytics/analytics_test.dart enforces it).
enum AnalyticsEvent {
  onboardingCompleted('onboarding_completed', {
    'breakup_type',
    'attachment_style',
    'focus',
  }),
  onboardingStepViewed('onboarding_step_viewed', {'step'}),
  notifPreprompt('notif_preprompt', {'result', 'hour'}),
  planReadyView('plan_ready_view', {}),
  paywallView('paywall_view', {
    'variant',
    'trigger',
    'offering_id',
    'trial_eligible',
  }),
  paywallClosed('paywall_closed', {'variant', 'trigger', 'time_on_screen_ms'}),
  planSelected('plan_selected', {'product_id', 'variant'}),
  remindToggle('remind_toggle', {'on'}),
  purchaseStarted('purchase_started', {
    'product_id',
    'offering_id',
    'trigger',
    'variant',
  }),
  purchaseCompleted('purchase_completed', {
    'product_id',
    'offering_id',
    'trigger',
    'variant',
    'is_trial',
  }),
  purchaseCancelled('purchase_cancelled', {'product_id', 'trigger'}),
  purchaseFailed('purchase_failed', {'product_id', 'error_code'}),
  purchasePending('purchase_pending', {'product_id'}),
  restoreTapped('restore_tapped', {'source'}),
  restoreCompleted('restore_completed', {'found'}),
  exitOfferShown('exit_offer_shown', {}),
  exitOfferClaimed('exit_offer_claimed', {}),
  exitOfferDismissed('exit_offer_dismissed', {}),
  limitHit('limit_hit', {'kind', 'free_used'}),
  limitSheetAction('limit_sheet_action', {'kind', 'action'}),
  coinsStoreView('coins_store_view', {'source'}),
  coinsPurchased('coins_purchased', {'product_id', 'coins'}),
  coinsSpent('coins_spent', {'item', 'cost', 'balance_after'}),
  planDayCompleted('plan_day_completed', {'day'}),
  draftLocked('draft_locked', {'origin'}),
  trialStatusView('trial_status_view', {'days_left'}),
  winbackShown('winback_shown', {}),
  winbackClaimed('winback_claimed', {}),
  winbackDismissed('winback_dismissed', {}),
  cancelSurveyShown('cancel_survey_shown', {}),
  cancelReason('cancel_reason', {'reason', 'offer_shown'}),
  cancelOfferAccepted('cancel_offer_accepted', {'reason'}),
  manageSubscriptionOpened('manage_subscription_opened', {'source'}),

  /// Safety monitoring only. Never used for targeting or monetization.
  sosOpened('sos_opened', {'from'});

  const AnalyticsEvent(this.wire, this.allowedProps);
  final String wire;
  final Set<String> allowedProps;

  /// Added to every event (M9).
  static const commonProps = {'locale', 'app_version', 'is_premium'};
}
