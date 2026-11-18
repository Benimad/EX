# MyEx KPIs (M9)

Client events come from the typed facade in `lib/core/analytics/analytics.dart` (event list:
`lib/core/analytics/events.dart`). Every event carries `locale`, `app_version`, `is_premium`.
Properties are allowlisted per event; no chat, journal, draft, plan text or names ever leave the app
(`test/analytics/analytics_test.dart`). Users are identified by the Supabase uid, which is also the
RevenueCat app user id. No IDFA, no ATT prompt.

**Server truth** (trial started/converted/cancelled, renewal, expiration, refund, billing issue) must come
from RevenueCat, not the client: either the native RevenueCat → `[ANALYTICS_PROVIDER]` integration, or events
emitted by `supabase/functions/revenuecat-webhook`. Filter `environment = SANDBOX` out of every dashboard.

Status: the provider adapter (`ProviderAnalyticsSink`) is a stub until `[ANALYTICS_PROVIDER]` is chosen;
in debug builds events print to the console (`DebugAnalyticsSink`).

| KPI | Definition / formula | Source |
|---|---|---|
| Install → quiz done | `onboarding_completed` / installs | client |
| Install → trial start % | trial starts / installs, split by `paywall_view.trigger` and `variant` | RevenueCat (INITIAL_PURCHASE, period TRIAL) + client |
| Trial → paid % | conversions / trial starts, cohort by trial-start week | RevenueCat (RENEWAL after trial) |
| Paywall CVR by trigger | `purchase_completed` / `paywall_view`, per `trigger` | client |
| Paywall time to decision | median `paywall_closed.time_on_screen_ms` | client |
| Exit offer take rate | `exit_offer_claimed` / `exit_offer_shown` | client |
| Exit offer cannibalization | share of `myex_annual_intro_50` among annual purchases vs. baseline cohort | RevenueCat |
| ARPU (D30, D90) | revenue / installs, by install cohort | RevenueCat + installs |
| ARPPU | revenue / paying users | RevenueCat |
| Retention D1 / D7 / D30 | active on day N, split free / trial / paid | provider (app open) |
| Plan engagement | `plan_day_completed` per active user per week; % reaching Day 3, 7, 30 | client |
| Refund rate | refunds / paid transactions | RevenueCat (CANCELLATION, CUSTOMER_SUPPORT) |
| Coin attach rate | % of non-subscribers with `coins_purchased` | client + RevenueCat |
| Coins spent per item | sum `coins_spent.cost` by `item` | client (+ `coin_ledger`) |
| Limit friction | `limit_hit` per active free user; `limit_sheet_action` mix | client |
| Cancel reasons | distribution of `cancel_reason.reason` | client (+ `cancel_survey_responses`) |
| Save rate | `cancel_offer_accepted` / `cancel_reason` with an offer shown | client |
| Win-back take rate | `winback_claimed` / `winback_shown` | client |
| Draft Jail use | `draft_locked` per active user, `origin` split | client |
| **SOS usage (safety)** | `sos_opened` by `from` | client. **Never** used for targeting, monetization or experiments. |

Benchmarks vary widely by category and price. Treat public numbers as directional and compare against
your own cohorts.

## Experiments
Default: RevenueCat Experiments, offerings `default` (timeline) vs `default_compare` (compare), new customers
only, 50/50. The client reads `offerings.current.metadata.paywall_variant`, so no release is needed.
Primary metric: revenue per paywall viewer at 14+ days. Secondary: trial start rate, trial → paid.
Pre-register the duration (≥ 2 full weeks) and minimum sample; one experiment at a time on the main paywall.
