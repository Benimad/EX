# MyEx — Monetization Prompt Pack (Flutter · Supabase · RevenueCat)

A prompt pack for building the MyEx monetization system with an AI coding agent (Claude Code or Cursor). It covers the paywall, trial, exit offer, free limits, coins, entitlement mirroring, reminders, the subscription hub, win-back and analytics.

**Reference prototype:** `MyEx_Glass_Premium.html`. It is the source of truth for the funnel, screen order, copy tone and numbers (`CFG`). Each screen's `why` text explains its intent. When a prompt and the prototype disagree on something visual, follow the prototype. When they disagree on compliance or security, follow this file.

## How to use

1. **Order:** M0 → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → MR. Do not skip M2/M3: the client UI (M5+) assumes the server schema and webhook exist.
2. **M0 is persistent context.** Paste it at the start of every new agent session, or save it as `CLAUDE.md` (Claude Code) or `.cursor/rules/monetization.mdc` (Cursor). Then paste one phase prompt per session.
3. **One phase = one PR.** Ask the agent to stop after each phase, list the files it changed and the acceptance checks it ran. Review the result yourself before starting the next phase.
4. **M1 is mostly manual.** It's a checklist for you (the founder) in App Store Connect and the RevenueCat dashboard. The agent can only produce the config files and docs.
5. **Replace placeholders** before pasting. Search for `[`:

| Placeholder | What it is | Where you get it |
|---|---|---|
| `[BUNDLE_ID]` | iOS bundle id, e.g. `app.myex.ios` | Xcode / App Store Connect |
| `[APP_STORE_APP_ID]` | Numeric Apple app id | App Store Connect › App Information |
| `[RC_API_KEY_IOS]` | RevenueCat **public** Apple SDK key (`appl_...`) | RevenueCat › Project › API keys |
| `[RC_SECRET_API_KEY]` | RevenueCat **secret** key (server only, never in the app) | RevenueCat › API keys |
| `[RC_WEBHOOK_AUTH]` | Long random string you invent (≥ 32 chars) | `openssl rand -hex 32` |
| `[SUPABASE_PROJECT_REF]` | Supabase project ref | Supabase dashboard URL |
| `[PROVIDER]` | Push provider for server push: `APNs direct`, `OneSignal`, or `FCM` | Your choice |
| `[ANALYTICS_PROVIDER]` | `PostHog`, `Mixpanel`, or `Amplitude` | Your choice |
| `[TERMS_URL]`, `[PRIVACY_URL]` | Hosted Terms of Use (EULA) and Privacy Policy | Your site |
| `[SUPPORT_EMAIL]` | Support address shown in the hub | — |
| `[HELPLINE_TR]`, `[HELPLINE_US]`, `[EMERGENCY_TR]`, `[EMERGENCY_US]` | Crisis lines per locale (e.g. 112 for TR emergency, 988 for US crisis line). **Verify the numbers yourself before release.** | Official sources |
| `[PRICE_*]` | Price tiers. Set **only** in App Store Connect, never in code | ASC |

Prototype example prices (USD, for ASC setup only, **never in code**): annual 49.99 with 7-day trial, monthly 12.99, exit offer annual 24.99 for the first year, win-back 9.99 for 3 months, coins 2.99 / 6.99 / 14.99.

---

## Prompt M0 — Monetization master context

```text
You are a principal mobile engineer and senior product designer. You have shipped subscription apps
with Flutter, Supabase and RevenueCat. You are building the monetization system of "MyEx".
Write production code. No mocks, no TODO stubs left in shipped paths, no invented APIs.
If you are not sure an API exists in the installed package version, open the package source or
docs in the repo (pubspec.lock version) and verify it. If you cannot verify it, write
"// VERIFY: <what>" and tell me in your summary.

## Product
MyEx is an iPhone app (Flutter, iOS 17+ target, iOS 26 visual language) for breakup recovery:
- AI coach "Mira": LLM through a Supabase Edge Function.
- Guided 30-day plan (plus a "Rebuild" stage), a no-contact streak, an SOS screen with crisis helplines,
  "Draft Jail" (locks a text to the ex for 24h), a journal, and relationship analysis.
- Languages: English and Turkish (ARB/intl). Mascot: "Lumi", a heart character.
- Backend: Supabase (Postgres + RLS, Auth with Apple/Google/email + anonymous sign-in,
  Edge Functions on Deno). Payments: RevenueCat (purchases_flutter) on the App Store.

## Monetization model (source of truth: MyEx_Glass_Premium.html, CFG + SC + ACT)
- Entitlement id: "premium". Subscription group "MyEx Premium":
  myex_premium_annual (7-day free trial), myex_premium_monthly (no trial),
  myex_annual_intro_50 (annual with a pay-up-front intro price for year 1, used ONLY for the one-time exit offer).
- Consumable coin packs: coins_30 (30), coins_80 (80 + 10 bonus), coins_200 (200 + 40 bonus).
- Coin costs: 20 extra Mira messages = 10, unlock one plan day = 15, full analysis = 30.
- Premium gets 50 bonus coins per month.
- Free tier: plan days 1–3, 3 Mira messages/day (the day resets at 09:00 in the user's local time),
  1 analysis insight, Draft Jail 1/day.
- Funnel: Onboarding → "Plan ready" (personalized) → Paywall (annual preselected, 7-day trial,
  billed yearly price as the main price, small "{monthlyEquivalent}/month" under it, NO per-week price; monthly as the alternative; trial timeline; "remind me" toggle; close + restore always visible)
  → first close only: exit offer sheet (shown once per user, ever) → Welcome (after purchase) → Home.
- Soft-limit sheets: Coach (Premium / 10 coins for 20 messages / wait), locked plan day
  (Premium / 15 coins), analysis (Premium / 30 coins).
- Lifecycle: local notification 2 days before the trial ends (value recap) + server push backup,
  a Trial status screen, the subscription hub in "Me", a cancel survey that never blocks the cancel,
  and a win-back offer 7–14 days after expiry.

## HARD RULES (never violate; if a request conflicts, refuse that part and tell me)
1. SOS, crisis helplines and the crisis sheet are ALWAYS free and never show a paywall, limit, coin price,
   upsell, or premium badge. Messages in a Mira conversation started from SOS (origin = 'sos')
   NEVER count toward any limit. The server enforces this, and SOS conversations use a crisis-safe system prompt.
2. The server is authoritative. The client never decides premium, limits, or coin balances for anything
   that unlocks content or costs money. The client may display cached state, but the Edge Functions/RPCs decide.
3. Coins are credited ONLY by the RevenueCat webhook (or the server sync fallback that reads the RevenueCat
   REST API with the secret key). They are idempotent by store transaction id. They are spent ONLY through the
   `spend_coins` RPC, which uses row locking. Purchased coins never expire (App Store Guideline 3.1.1).
4. Never hardcode prices, currencies or trial lengths in UI. Always use RevenueCat
   `package.storeProduct.priceString` / `introductoryPrice` / `currencyCode`. Derived values (monthly-equivalent price,
   savings %) are computed from StoreKit numbers and formatted with intl using the device locale
   (tr_TR shows "₺" and a comma decimal, and Turkish puts the percent sign first: "%40").
5. Secrets: only [RC_API_KEY_IOS] (the public SDK key) ships in the app. The RevenueCat secret key,
   the webhook auth token and the Supabase service role key live only in Edge Function secrets.

## Ethics + App Store compliance (Guidelines 3.1.1, 3.1.2, 5.1.1, 1.4.1)
- No fake urgency: no countdown timers, no "offer ends in 10:00", no "only 3 spots left".
  "We only show this once" is allowed ONLY because the server enforces it.
- No fake reviews, ratings, user counts, or testimonials. No "most popular" claim unless it is true;
  use "Best value" (computed) instead.
- The paywall shows, before purchase: the subscription name, duration, billed price, what happens after the
  trial, cancel instructions, and links to Terms of Use (EULA) [TERMS_URL] and Privacy [PRIVACY_URL]. The
  billed amount ("€49.99/year") is the main, largest price. No per-week price anywhere (design spec); a small monthly equivalent is allowed as secondary text.
- The close (X) button is visible immediately: no delay and no fade-in. Restore Purchases is always visible.
- If the user is not eligible for the intro offer, never say "free"; the CTA becomes "Subscribe".
- The cancel survey is optional. "Continue to cancel" is visible from the first frame and always deep-links to
  App Store subscription management. Never ask for the reason before showing the exit.
- No medical claims. Mira is not therapy. The crisis copy points to real humans.
- All digital unlocks (subscriptions and coins) use In-App Purchase. No external payment links.

## Design tokens (Light "Love" theme)
bg #FFF4F6 · ink #3A0F22 · muted #86506A · primary #D81B60 · success #0B7A55 · danger #D11541
surface (solid card) #FFFFFF · hairline rgba(58,15,34,0.08)
Display: Instrument Serif (headlines, italic accents for <em>). UI: Plus Jakarta Sans (400/500/700/800).
Bundle the fonts as assets (OFL), and don't fetch them at runtime.
iOS Liquid Glass goes on NAVIGATION AND CONTROLS ONLY (tab bar, nav buttons, sheets, chips, the paywall dock).
Content sits on solid cards. Glass = BackdropFilter blur + translucent white fill + 1px white border.
Reduce Transparency ON → every glass surface becomes solid #FFFFFF with a hairline border and no blur.
Reduce Motion ON → no confetti, no count-up animations, no parallax; use cross-fades only.
Minimum tap target 44×44, Dynamic Type up to accessibility sizes without clipping, VoiceOver labels on
every control (plan cards announce: name, billed price, monthly equivalent, trial, selected state).

## Code conventions
- Flutter stable, Dart 3, Riverpod (riverpod_annotation is optional, but match the repo), go_router if present.
- Feature folder: lib/features/monetization/{data,domain,application,presentation}.
- Supabase migrations in supabase/migrations/, Edge Functions in supabase/functions/<name>/index.ts.
- All user-facing strings in lib/l10n/app_en.arb and app_tr.arb. Use ICU plurals for English.
- Every phase ends with: a files-changed list, the acceptance checks you ran, and the open VERIFY items.

## Quality bar
- Purchases never double-charge or double-credit, even with retries, app kills, or duplicate webhooks.
- Every async UI state is handled: loading (skeleton, never placeholder prices), error (retry +
  "Continue free"), cancelled (silent), pending/Ask to Buy (calm message), success.
- Unit tests for pure logic (price formatting, eligibility mapping, limit state). SQL tests for RPCs
  (pgTAP or plain SQL scripts). A manual sandbox test script for purchases.
```

---

## Prompt M1 — App Store Connect + RevenueCat setup

```text
Goal: Produce the exact store + RevenueCat configuration for MyEx, plus a checklist I (the founder) can
follow click by click, and the app-side config file the code will read. Do not write purchase code yet.

Build:
1. docs/monetization/STORE_SETUP.md: a checklist with checkboxes, covering:

   App Store Connect ([BUNDLE_ID], app id [APP_STORE_APP_ID])
   - Agreements, Tax and Banking: Paid Apps agreement ACTIVE (purchases fail silently in sandbox without it).
   - In-App Purchase capability enabled on the App ID and in Xcode (Signing & Capabilities).
   - Subscription group "MyEx Premium" (one group, so up/down/crossgrades work), with localized display
     names EN + TR. Levels: annual and annual_intro at the same level, monthly below (verify level semantics).
       * myex_premium_annual: 1 year. Introductory offer: Free trial, 1 week, all territories.
       * myex_premium_monthly: 1 month, no intro offer.
       * myex_annual_intro_50: 1 year. Introductory offer: Pay up front, 1 year, [PRICE_EXIT_OFFER].
         Exists ONLY for the exit offer. Note: intro offers are once per subscription group per Apple ID,
         so a user who already had the trial is NOT eligible. The app must check eligibility.
       * Promotional offers (need an In-App Purchase Key, see RevenueCat below):
         - on myex_premium_annual: "save50_annual" = pay up front 1 year at 50%. Used in the cancel
           survey ("too expensive").
         - on myex_premium_monthly: "winback_3m" = pay up front 3 months [PRICE_WINBACK]. Used for lapsed
           users 7–14 days after expiry.
       * Optional, iOS 18+: an Apple win-back offer on monthly (system-managed eligibility). VERIFY RevenueCat
         support in the installed SDK version before using it. The promotional offer above remains the default.
     - Billing Grace Period: ON (16 days), with eligibility for all renewals.
     - Family Sharing: OFF for v1 (it can't be turned off once enabled). Decide consciously.
     - Review screenshot of the paywall + review notes for each product.
   - Consumables: coins_30, coins_80, coins_200, each with EN + TR display names
     ("30 Coins" / "30 Jeton", "80 + 10 Coins" / "80 + 10 Jeton", "200 + 40 Coins" / "200 + 40 Jeton").
   - App Store Server Notifications V2: Production + Sandbox URL = the RevenueCat-provided URL
     (RevenueCat › App settings › Apple Server Notifications). Faster refund/renewal detection.
   - Sandbox testers: 2 accounts (EN storefront, TR storefront).
   - App description includes a Terms of Use link (or a custom EULA in ASC) and a Privacy Policy URL.

   RevenueCat ([RC_API_KEY_IOS])
   - Project "MyEx" › App Store app with [BUNDLE_ID]. Upload the In-App Purchase Key (.p8) + issuer id +
     key id. This is required for promotional offers and StoreKit 2 validation.
   - Products: import all 6 products.
   - Entitlement "premium" ← attach myex_premium_annual, myex_premium_monthly, myex_annual_intro_50.
     The coin consumables are NOT attached to any entitlement.
   - Offerings (identifier → packages → metadata):
       * default            → $rc_annual: myex_premium_annual, $rc_monthly: myex_premium_monthly
                              metadata {"paywall_variant":"timeline"}  (mark as CURRENT)
       * default_compare    → same packages, metadata {"paywall_variant":"compare"}
       * exit_offer         → $rc_annual: myex_annual_intro_50   metadata {"kind":"exit"}
       * winback            → $rc_monthly: myex_premium_monthly  metadata {"promo_offer_id":"winback_3m"}
       * coins              → custom packages "coins_30", "coins_80", "coins_200"
                              metadata {"popular":"coins_80","best_value":"coins_200"}
   - Experiment (later, M9): default vs default_compare, 50/50, new customers only.
   - Webhook: URL https://[SUPABASE_PROJECT_REF].supabase.co/functions/v1/revenuecat-webhook,
     Authorization header value: "Bearer [RC_WEBHOOK_AUTH]", environment: both production and sandbox
     (App Review and TestFlight purchase in SANDBOX, so the backend must accept sandbox).
   - Project settings › "Transfer behavior": keep the default (transfer to new App User ID) and document it.
   - Optional: the native RevenueCat → [ANALYTICS_PROVIDER] integration for server-side subscription events.

2. lib/features/monetization/domain/monetization_ids.dart: constants for the entitlement id, offering ids,
   product ids, promo offer ids and coin item ids. No prices.

3. ios/MyEx.storekit: an Xcode StoreKit Configuration file mirroring the products (for local testing only).
   Document how to switch the scheme between the StoreKit config and the sandbox.

Acceptance criteria:
- STORE_SETUP.md lets a non-engineer configure everything without guessing. Every step names the exact screen.
- Product ids in the code exactly match ASC, RevenueCat and the prototype CFG.
- Nothing in the repo contains a price, the secret key, or the webhook token.

Files to create:
docs/monetization/STORE_SETUP.md
lib/features/monetization/domain/monetization_ids.dart
ios/MyEx.storekit (+ a scheme note in STORE_SETUP.md)
```

---

## Prompt M2 — Supabase schema, RLS and RPCs

```text
Goal: Build the server-authoritative data layer: the entitlement mirror on profiles, the coin wallet + ledger,
usage counters with a 09:00-local reset, content unlocks, webhook event log, cancel survey answers, and RPCs.
Use the SQL below as the baseline. Adapt table names to the existing schema (ask me if profiles,
conversations, plan or analysis tables differ), and keep the security model exactly as written.

Build:
1. supabase/migrations/<ts>_monetization.sql (content below, adapted).
2. supabase/tests/monetization_test.sql: SQL tests (pgTAP if installed, else DO blocks with ASSERT):
   - an authenticated user cannot update premium_* columns, message_credits, or coin tables
   - spend_coins with an insufficient balance → ok=false, and the balance is unchanged
   - spend_coins replayed with the same key → spends once
   - 50 concurrent spend_coins calls (pgbench or parallel psql) never drive the balance negative
   - credit_coins with the same key twice → credits once
   - consume_quota('message','sos') never increments messages_used, even after the limit
   - usage_day_for flips at 09:00 local (test Europe/Istanbul and America/New_York)
3. Enable pg_cron and schedule the monthly bonus job (SQL below).

Acceptance criteria:
- `supabase db reset` applies cleanly. All tests pass.
- Security advisor (Supabase dashboard › Advisors) shows no RLS warnings for the new tables.
- Every SECURITY DEFINER function has `set search_path = ''` and fully-qualified names.

Files to create:
supabase/migrations/<timestamp>_monetization.sql
supabase/tests/monetization_test.sql
```

```sql
-- ============ PROFILES: entitlement mirror (written only by service_role) ============
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists timezone                 text not null default 'UTC',
  add column if not exists timezone_changed_at      timestamptz,
  add column if not exists locale                   text not null default 'en',
  add column if not exists premium_expires_at       timestamptz,       -- includes grace period
  add column if not exists premium_period_type      text,              -- 'trial' | 'intro' | 'normal' | 'promotional'
  add column if not exists premium_product_id       text,
  add column if not exists premium_will_renew       boolean,
  add column if not exists premium_billing_issue_at timestamptz,
  add column if not exists premium_is_sandbox       boolean not null default false,
  add column if not exists premium_synced_at        timestamptz,
  add column if not exists trial_started_at         timestamptz,
  add column if not exists had_premium              boolean not null default false,
  add column if not exists premium_lapsed_at        timestamptz,
  add column if not exists exit_offer_shown_at      timestamptz,
  add column if not exists winback_shown_at         timestamptz,
  add column if not exists message_credits          int not null default 0 check (message_credits >= 0);

alter table public.profiles enable row level security;
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Column-level privileges: clients may only edit harmless columns.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (timezone, locale) on public.profiles to authenticated;   -- add display_name etc. if they exist

-- Anti-abuse: changing timezone to reset the daily counter is allowed at most once per 24h.
create or replace function public.guard_timezone_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.timezone is distinct from old.timezone then
    if not exists (select 1 from pg_catalog.pg_timezone_names where name = new.timezone) then
      raise exception 'invalid timezone';
    end if;
    if old.timezone_changed_at is not null and old.timezone_changed_at > now() - interval '24 hours' then
      new.timezone := old.timezone;               -- silently keep the old one
    else
      new.timezone_changed_at := now();
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_guard_timezone on public.profiles;
create trigger trg_guard_timezone before update of timezone on public.profiles
  for each row execute function public.guard_timezone_change();

-- ============ PREMIUM CHECK ============
create or replace function public.is_premium(p_uid uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select p.premium_expires_at > now() from public.profiles p where p.id = p_uid), false);
$$;
revoke execute on function public.is_premium(uuid) from public, anon;
grant execute on function public.is_premium(uuid) to authenticated, service_role;

-- ============ COINS ============
create table if not exists public.coin_packs (          -- product_id -> coins credited
  product_id text primary key,
  coins int not null check (coins > 0),
  bonus int not null default 0 check (bonus >= 0)
);
insert into public.coin_packs values ('coins_30',30,0),('coins_80',80,10),('coins_200',200,40)
  on conflict (product_id) do update set coins = excluded.coins, bonus = excluded.bonus;

create table if not exists public.coin_catalog (        -- what coins buy (server-side prices)
  item text primary key,                               -- 'msgs_20' | 'plan_day' | 'analysis'
  cost int not null check (cost > 0),
  grant_qty int not null default 1
);
insert into public.coin_catalog values ('msgs_20',10,20),('plan_day',15,1),('analysis',30,1)
  on conflict (item) do update set cost = excluded.cost, grant_qty = excluded.grant_qty;

create table if not exists public.coin_wallets (
  user_id uuid primary key references auth.users on delete cascade,
  balance int not null default 0,                      -- may go negative only via refund clawback
  updated_at timestamptz not null default now()
);

create table if not exists public.coin_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,
  delta int not null check (delta <> 0),
  kind text not null check (kind in ('purchase','premium_bonus','spend','refund_clawback','admin_adjust')),
  item text,
  ref text,
  idempotency_key text not null unique,                -- 'iap:<txn>', 'bonus:<uid>:<YYYY-MM>', 'spend:<uid>:<key>', 'refund:<txn>'
  balance_after int not null,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists coin_ledger_user_idx on public.coin_ledger (user_id, created_at desc);

create table if not exists public.content_unlocks (
  user_id uuid not null references auth.users on delete cascade,
  kind text not null check (kind in ('plan_day','analysis')),
  ref text not null,                                   -- day number or analysis id
  created_at timestamptz not null default now(),
  primary key (user_id, kind, ref)
);

alter table public.coin_packs      enable row level security;
alter table public.coin_catalog    enable row level security;
alter table public.coin_wallets    enable row level security;
alter table public.coin_ledger     enable row level security;
alter table public.content_unlocks enable row level security;

create policy coin_packs_read   on public.coin_packs   for select to authenticated using (true);
create policy coin_catalog_read on public.coin_catalog for select to authenticated using (true);
create policy wallet_read_own   on public.coin_wallets for select to authenticated using ((select auth.uid()) = user_id);
create policy ledger_read_own   on public.coin_ledger  for select to authenticated using ((select auth.uid()) = user_id);
create policy unlocks_read_own  on public.content_unlocks for select to authenticated using ((select auth.uid()) = user_id);
-- No insert/update/delete policies: all writes go through SECURITY DEFINER functions.

-- Reconciliation view (admin only): the wallet must equal the ledger sum.
create or replace view public.coin_balance_audit with (security_invoker = true) as
  select w.user_id, w.balance, coalesce(sum(l.delta),0) as ledger_sum,
         w.balance - coalesce(sum(l.delta),0) as drift
  from public.coin_wallets w left join public.coin_ledger l using (user_id)
  group by w.user_id, w.balance;
revoke all on public.coin_balance_audit from anon, authenticated;

-- credit_coins: service_role only (webhook + sync). Negative amounts = refund clawback.
create or replace function public.credit_coins(
  p_uid uuid, p_amount int, p_kind text, p_key text, p_meta jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_bal int;
begin
  insert into public.coin_wallets (user_id) values (p_uid) on conflict do nothing;
  select balance into v_bal from public.coin_wallets where user_id = p_uid for update;
  if exists (select 1 from public.coin_ledger where idempotency_key = p_key) then
    return jsonb_build_object('credited', false, 'duplicate', true, 'balance', v_bal);
  end if;
  update public.coin_wallets set balance = balance + p_amount, updated_at = now()
    where user_id = p_uid returning balance into v_bal;
  insert into public.coin_ledger (user_id, delta, kind, idempotency_key, balance_after, meta)
    values (p_uid, p_amount, p_kind, p_key, v_bal, p_meta);
  return jsonb_build_object('credited', true, 'balance', v_bal);
end $$;
revoke execute on function public.credit_coins(uuid,int,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.credit_coins(uuid,int,text,text,jsonb) to service_role;

-- Premium bonus: once per calendar month per user (keyed), from the webhook or the cron job.
create or replace function public.grant_premium_bonus(p_uid uuid, p_month text default to_char(now(),'YYYY-MM'))
returns jsonb language sql security definer set search_path = '' as $$
  select public.credit_coins(p_uid, 50, 'premium_bonus', 'bonus:' || p_uid || ':' || p_month,
                             jsonb_build_object('month', p_month));
$$;
revoke execute on function public.grant_premium_bonus(uuid,text) from public, anon, authenticated;
grant execute on function public.grant_premium_bonus(uuid,text) to service_role;

-- spend_coins: called by the app (authenticated). Prices come from coin_catalog, never from the client.
create or replace function public.spend_coins(p_item text, p_ref text, p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_cost int; v_qty int; v_bal int; v_key text; v_prev public.coin_ledger%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then raise exception 'bad idempotency key'; end if;
  select cost, grant_qty into v_cost, v_qty from public.coin_catalog where item = p_item;
  if not found then raise exception 'unknown item %', p_item; end if;

  if p_item = 'plan_day' then
    if p_ref !~ '^[0-9]{1,2}$' or p_ref::int not between 4 and 30 then raise exception 'bad day'; end if;
  elsif p_item = 'analysis' then
    -- ADAPT: verify the analysis belongs to the user, e.g.
    -- if not exists (select 1 from public.analyses a where a.id = p_ref::uuid and a.user_id = v_uid) then raise exception 'not found'; end if;
    null;
  end if;

  if p_item in ('plan_day','analysis') then
    if public.is_premium(v_uid) then
      return jsonb_build_object('ok', false, 'reason', 'premium_has_access');
    end if;
    if exists (select 1 from public.content_unlocks where user_id = v_uid and kind = p_item and ref = p_ref) then
      return jsonb_build_object('ok', true, 'already_unlocked', true);
    end if;
  end if;

  insert into public.coin_wallets (user_id) values (v_uid) on conflict do nothing;
  select balance into v_bal from public.coin_wallets where user_id = v_uid for update;   -- serializes spends

  v_key := 'spend:' || v_uid || ':' || p_idempotency_key;
  select * into v_prev from public.coin_ledger where idempotency_key = v_key;
  if found then return jsonb_build_object('ok', true, 'replayed', true, 'balance', v_bal); end if;

  if v_bal < v_cost then
    return jsonb_build_object('ok', false, 'reason', 'insufficient', 'balance', v_bal, 'cost', v_cost);
  end if;

  update public.coin_wallets set balance = balance - v_cost, updated_at = now()
    where user_id = v_uid returning balance into v_bal;
  insert into public.coin_ledger (user_id, delta, kind, item, ref, idempotency_key, balance_after)
    values (v_uid, -v_cost, 'spend', p_item, p_ref, v_key, v_bal);

  if p_item = 'msgs_20' then
    update public.profiles set message_credits = message_credits + v_qty where id = v_uid;
  else
    insert into public.content_unlocks (user_id, kind, ref) values (v_uid, p_item, p_ref) on conflict do nothing;
  end if;

  return jsonb_build_object('ok', true, 'balance', v_bal, 'item', p_item, 'ref', p_ref);
end $$;
revoke execute on function public.spend_coins(text,text,text) from public, anon;
grant execute on function public.spend_coins(text,text,text) to authenticated;

-- ============ USAGE (free limits, 09:00 local reset) ============
create table if not exists public.usage_counters (
  user_id uuid not null references auth.users on delete cascade,
  usage_day date not null,
  messages_used int not null default 0,
  sos_messages int not null default 0,                -- telemetry only, never limited
  drafts_used int not null default 0,
  primary key (user_id, usage_day)
);
alter table public.usage_counters enable row level security;
create policy usage_read_own on public.usage_counters for select to authenticated using ((select auth.uid()) = user_id);

create or replace function public.usage_day_for(p_tz text, p_at timestamptz default now())
returns date language sql stable set search_path = '' as $$
  select ((p_at at time zone coalesce(nullif(p_tz,''),'UTC')) - interval '9 hours')::date;
$$;

-- consume_quota: service_role only (called by the mira-chat / draft-jail Edge Functions).
create or replace function public.consume_quota(p_uid uuid, p_kind text, p_origin text default 'normal')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  c_free_msgs constant int := 3;
  c_free_drafts constant int := 1;
  v_tz text; v_day date; v_row public.usage_counters%rowtype; v_credits int; v_resets timestamptz;
begin
  if p_kind not in ('message','draft') then raise exception 'bad kind'; end if;
  select coalesce(timezone,'UTC') into v_tz from public.profiles where id = p_uid;
  v_day := public.usage_day_for(v_tz);
  v_resets := ((v_day + 1)::timestamp + interval '9 hours') at time zone v_tz;
  insert into public.usage_counters (user_id, usage_day) values (p_uid, v_day) on conflict do nothing;

  -- HARD RULE: SOS never counts and is never blocked.
  if p_kind = 'message' and p_origin = 'sos' then
    update public.usage_counters set sos_messages = sos_messages + 1 where user_id = p_uid and usage_day = v_day;
    return jsonb_build_object('allowed', true, 'counted', false, 'via', 'sos');
  end if;

  if public.is_premium(p_uid) then
    return jsonb_build_object('allowed', true, 'counted', false, 'via', 'premium');
  end if;

  select * into v_row from public.usage_counters where user_id = p_uid and usage_day = v_day for update;

  if p_kind = 'message' then
    if v_row.messages_used < c_free_msgs then
      update public.usage_counters set messages_used = messages_used + 1 where user_id = p_uid and usage_day = v_day;
      return jsonb_build_object('allowed', true, 'counted', true, 'via', 'free',
                                'free_left', c_free_msgs - v_row.messages_used - 1, 'resets_at', v_resets);
    end if;
    update public.profiles set message_credits = message_credits - 1
      where id = p_uid and message_credits > 0 returning message_credits into v_credits;
    if found then
      return jsonb_build_object('allowed', true, 'counted', true, 'via', 'credits', 'credits_left', v_credits);
    end if;
    return jsonb_build_object('allowed', false, 'reason', 'limit', 'resets_at', v_resets);
  else
    if v_row.drafts_used < c_free_drafts then
      update public.usage_counters set drafts_used = drafts_used + 1 where user_id = p_uid and usage_day = v_day;
      return jsonb_build_object('allowed', true, 'counted', true, 'via', 'free');
    end if;
    return jsonb_build_object('allowed', false, 'reason', 'limit', 'resets_at', v_resets);
  end if;
end $$;
revoke execute on function public.consume_quota(uuid,text,text) from public, anon, authenticated;
grant execute on function public.consume_quota(uuid,text,text) to service_role;

-- refund_message: service_role only. Gives a counted message back when the LLM call fails.
create or replace function public.refund_message(p_uid uuid, p_via text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_day date;
begin
  select public.usage_day_for(timezone) into v_day from public.profiles where id = p_uid;
  if p_via = 'free' then
    update public.usage_counters set messages_used = greatest(messages_used - 1, 0)
      where user_id = p_uid and usage_day = v_day;
  elsif p_via = 'credits' then
    update public.profiles set message_credits = message_credits + 1 where id = p_uid;
  end if;
end $$;
revoke execute on function public.refund_message(uuid,text) from public, anon, authenticated;
grant execute on function public.refund_message(uuid,text) to service_role;

-- Read-only status for the client meter (never trusted for enforcement).
create or replace function public.get_limits() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_tz text; v_day date; v_used int; v_drafts int; v_credits int;
begin
  select timezone, message_credits into v_tz, v_credits from public.profiles where id = v_uid;
  v_day := public.usage_day_for(v_tz);
  select messages_used, drafts_used into v_used, v_drafts from public.usage_counters where user_id = v_uid and usage_day = v_day;
  return jsonb_build_object('premium', public.is_premium(v_uid),
    'free_msgs_left', greatest(3 - coalesce(v_used,0), 0), 'message_credits', coalesce(v_credits,0),
    'drafts_left', greatest(1 - coalesce(v_drafts,0), 0),
    'resets_at', ((v_day + 1)::timestamp + interval '9 hours') at time zone coalesce(v_tz,'UTC'));
end $$;
grant execute on function public.get_limits() to authenticated;

-- ============ PLAN CONTENT GATING (adapt to your plan table) ============
-- Example: content for days 4–30 must never reach a free client.
-- create policy plan_days_read on public.plan_days for select to authenticated using (
--   day_number <= 3 or public.is_premium((select auth.uid()))
--   or exists (select 1 from public.content_unlocks u where u.user_id = (select auth.uid())
--              and u.kind = 'plan_day' and u.ref = plan_days.day_number::text));
-- Expose a separate public.plan_day_teasers (title, promise, duration) readable by all, so the client
-- can show locked days (prototype: "locked content is shown, not hidden").

-- ============ ONE-TIME FLAGS ============
create or replace function public.mark_exit_offer_shown() returns boolean
language plpgsql security definer set search_path = '' as $$
declare v_updated int;
begin
  update public.profiles set exit_offer_shown_at = now()
    where id = auth.uid() and exit_offer_shown_at is null;
  get diagnostics v_updated = row_count;
  return v_updated = 1;   -- true = this call "won" the right to show the offer
end $$;
grant execute on function public.mark_exit_offer_shown() to authenticated;

-- ============ WEBHOOK LOG + CANCEL SURVEY ============
create table if not exists public.webhook_events (
  id text primary key,                                -- RevenueCat event.id (idempotency)
  type text not null,
  app_user_id text,
  environment text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  error text
);
alter table public.webhook_events enable row level security;   -- no policies: service_role only

create table if not exists public.cancel_survey_responses (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  reason text not null check (reason in ('price','better','unused','other')),
  offer_shown text,
  offer_accepted boolean not null default false,
  note text check (length(note) <= 500),
  created_at timestamptz not null default now()
);
alter table public.cancel_survey_responses enable row level security;
create policy cancel_insert_own on public.cancel_survey_responses
  for insert to authenticated with check ((select auth.uid()) = user_id);

-- ============ MONTHLY BONUS FOR ANNUAL SUBSCRIBERS (monthly ones also get it from RENEWAL) ============
create or replace function public.grant_monthly_bonuses() returns int
language plpgsql security definer set search_path = '' as $$
declare r record; n int := 0;
begin
  for r in select id from public.profiles
           where premium_expires_at > now() and coalesce(premium_period_type,'normal') <> 'trial'
  loop
    perform public.grant_premium_bonus(r.id);   -- idempotent per calendar month
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.grant_monthly_bonuses() from public, anon, authenticated;
select cron.schedule('monthly-premium-bonus', '15 6 * * *', $$select public.grant_monthly_bonuses();$$);
-- Daily at 06:15 UTC. It is idempotent, so a missed day self-heals.
```

---

## Prompt M3 — RevenueCat webhook + sync Edge Functions

```text
Goal: Mirror RevenueCat state into Supabase and credit coins, securely and idempotently.

Build:
1. supabase/functions/_shared/revenuecat.ts: shared helpers (auth compare, user id resolution,
   fetching a subscriber from the RevenueCat REST API, entitlement sync, coin credit).
2. supabase/functions/revenuecat-webhook/index.ts: the webhook (code below). Deploy with
   `supabase functions deploy revenuecat-webhook --no-verify-jwt`, because RevenueCat does not send a Supabase JWT.
   Secrets: `supabase secrets set REVENUECAT_WEBHOOK_AUTH=[RC_WEBHOOK_AUTH] REVENUECAT_SECRET_API_KEY=[RC_SECRET_API_KEY]`.
3. supabase/functions/sync-purchases/index.ts: called by the app right after a purchase or restore
   (JWT required). It re-reads the subscriber from RevenueCat, syncs the entitlement, and credits any coin
   purchase the webhook hasn't credited yet, using the same idempotency key format (`iap:<store transaction id>`).
   This removes the "I paid but no coins" window if the webhook is slow.

Rules:
- Verify the Authorization header with a constant-time compare. Return 401 on mismatch.
- Idempotency by event.id (webhook_events PK) AND by transaction id for coins (coin_ledger.idempotency_key).
- Return 200 for duplicates and for events you intentionally ignore. Return 5xx only for transient errors,
  because RevenueCat retries non-2xx responses (verify the current retry policy in the docs).
- Do not trust the event to give the full state: for subscription events, re-fetch the subscriber from
  the REST API so out-of-order events can't corrupt the mirror.
- App user ids are Supabase auth UUIDs (the app calls Purchases.logIn(uid)). Ignore `$RCAnonymousID:` ids.
- Accept SANDBOX events (TestFlight + App Review), and store premium_is_sandbox for analytics filtering.
- Event types to handle: TEST, INITIAL_PURCHASE, RENEWAL, CANCELLATION, UNCANCELLATION,
  NON_RENEWING_PURCHASE, EXPIRATION, BILLING_ISSUE, PRODUCT_CHANGE, TRANSFER, SUBSCRIPTION_EXTENDED,
  TEMPORARY_ENTITLEMENT_GRANT, REFUND_REVERSED. Log and ignore unknown types (200).
- Refunds: RevenueCat sends CANCELLATION with cancel_reason = "CUSTOMER_SUPPORT". For coin packs, claw back
  (negative ledger entry, `refund:<txn>`). For subscriptions, the re-fetch handles revocation.
- Bonus coins: 50 on INITIAL_PURCHASE (trial included; matches the Welcome screen) and on RENEWAL,
  keyed per calendar month. No bonus for family-shared access (is_family_share = true).

Acceptance criteria:
- curl with the wrong token → 401. A RevenueCat dashboard "Send test event" → 200, logged.
- Replaying the same NON_RENEWING_PURCHASE twice → coins credited once.
- A sandbox monthly subscription (renews every 5 min) produces RENEWAL events, premium_expires_at moves
  forward, and the bonus is granted once per calendar month.
- After EXPIRATION, is_premium() is false and premium_lapsed_at is set.
- No secret appears in logs.

Files to create:
supabase/functions/_shared/revenuecat.ts
supabase/functions/revenuecat-webhook/index.ts
supabase/functions/sync-purchases/index.ts
supabase/config.toml ([functions.revenuecat-webhook] verify_jwt = false)
```

```ts
// supabase/functions/_shared/revenuecat.ts
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const admin: SupabaseClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const RC_SECRET = Deno.env.get("REVENUECAT_SECRET_API_KEY")!;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const ENTITLEMENT = "premium";

export function safeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a), eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) diff |= ea[i] ^ eb[i];
  return diff === 0;
}

export function resolveUserId(ev: Record<string, unknown>): string | null {
  const ids = [ev.app_user_id, ev.original_app_user_id, ...((ev.aliases as string[]) ?? [])];
  return (ids.find((id) => typeof id === "string" && UUID_RE.test(id)) as string) ?? null;
}

// RevenueCat REST v1. VERIFY field names against the current API reference (v2 exists too).
export async function fetchSubscriber(uid: string) {
  const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, {
    headers: { Authorization: `Bearer ${RC_SECRET}`, "Content-Type": "application/json" },
  });
  if (!res.ok) throw new Error(`RevenueCat ${res.status}`);
  return (await res.json()).subscriber as Record<string, any>;
}

export async function syncEntitlement(uid: string, opts: { trialStarted?: boolean; lapsed?: boolean } = {}) {
  const sub = await fetchSubscriber(uid);
  const ent = sub.entitlements?.[ENTITLEMENT];
  const s = ent ? sub.subscriptions?.[ent.product_identifier] : undefined;
  const dates = [ent?.expires_date, ent?.grace_period_expires_date, s?.grace_period_expires_date]
    .filter(Boolean).map((d: string) => new Date(d).getTime());
  const expires = dates.length ? new Date(Math.max(...dates)) : null;

  const patch: Record<string, unknown> = {
    premium_expires_at: expires?.toISOString() ?? null,
    premium_product_id: ent?.product_identifier ?? null,
    premium_period_type: s?.period_type ?? null,              // 'trial' | 'intro' | 'normal' | ...
    premium_will_renew: s ? s.unsubscribe_detected_at == null : null,
    premium_billing_issue_at: s?.billing_issues_detected_at ?? null,
    premium_is_sandbox: s?.is_sandbox ?? false,
    premium_synced_at: new Date().toISOString(),
  };
  if (expires && expires > new Date()) patch.had_premium = true;
  if (opts.trialStarted) patch.trial_started_at = new Date().toISOString();
  if (opts.lapsed && (!expires || expires <= new Date())) patch.premium_lapsed_at = new Date().toISOString();

  const { error } = await admin.from("profiles").upsert({ id: uid, ...patch }, { onConflict: "id" });
  if (error) throw error;
  return { active: !!expires && expires > new Date(), expires };
}

export async function creditPack(uid: string, productId: string, txnId: string, meta: Record<string, unknown>) {
  const { data: pack } = await admin.from("coin_packs").select("coins,bonus").eq("product_id", productId).maybeSingle();
  if (!pack) { console.warn("unknown coin product", productId); return null; }
  const { data, error } = await admin.rpc("credit_coins", {
    p_uid: uid, p_amount: pack.coins + pack.bonus, p_kind: "purchase",
    p_key: `iap:${txnId}`, p_meta: { product_id: productId, ...meta },
  });
  if (error) throw error;
  return data;
}

export async function isCoinProduct(productId: string): Promise<boolean> {
  const { data } = await admin.from("coin_packs").select("product_id").eq("product_id", productId).maybeSingle();
  return !!data;
}
```

```ts
// supabase/functions/revenuecat-webhook/index.ts
import { admin, creditPack, isCoinProduct, resolveUserId, safeEqual, syncEntitlement } from "../_shared/revenuecat.ts";

const EXPECTED = `Bearer ${Deno.env.get("REVENUECAT_WEBHOOK_AUTH")!}`;
const ok = (msg = "ok") => new Response(msg, { status: 200 });

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  if (!safeEqual(req.headers.get("authorization") ?? "", EXPECTED)) {
    return new Response("unauthorized", { status: 401 });
  }

  let body: any;
  try { body = await req.json(); } catch { return new Response("bad json", { status: 400 }); }
  const ev = body?.event;
  if (!ev?.id || !ev?.type) return new Response("bad event", { status: 400 });

  // Idempotency gate on event.id
  const ins = await admin.from("webhook_events").insert({
    id: ev.id, type: ev.type, app_user_id: ev.app_user_id ?? null,
    environment: ev.environment ?? null, payload: body,
  });
  if (ins.error) {
    if (ins.error.code !== "23505") return new Response("db error", { status: 500 });
    const { data } = await admin.from("webhook_events").select("processed_at").eq("id", ev.id).single();
    if (data?.processed_at) return ok("duplicate");
  }

  try {
    await handle(ev);
    await admin.from("webhook_events").update({ processed_at: new Date().toISOString(), error: null }).eq("id", ev.id);
    return ok();
  } catch (e) {
    console.error("webhook failed", ev.type, ev.id, String(e));
    await admin.from("webhook_events").update({ error: String(e).slice(0, 500) }).eq("id", ev.id);
    return new Response("retry", { status: 500 });   // RevenueCat retries
  }
});

async function handle(ev: any) {
  if (ev.type === "TEST") return;

  if (ev.type === "TRANSFER") {
    const ids: string[] = [...(ev.transferred_from ?? []), ...(ev.transferred_to ?? [])];
    for (const id of ids) if (/^[0-9a-f-]{36}$/i.test(id)) await syncEntitlement(id);
    return;
  }

  const uid = resolveUserId(ev);
  if (!uid) { console.warn("no supabase uid on event", ev.type, ev.id); return; }
  const txn: string = ev.transaction_id ?? ev.id;   // VERIFY: transaction_id = store transaction id
  const coin = ev.product_id ? await isCoinProduct(ev.product_id) : false;

  switch (ev.type) {
    case "NON_RENEWING_PURCHASE":
      if (coin) await creditPack(uid, ev.product_id, txn, { env: ev.environment, store: ev.store });
      return;

    case "CANCELLATION":
      if (coin) {
        if (ev.cancel_reason === "CUSTOMER_SUPPORT") await clawback(uid, ev.product_id, txn);
        return;
      }
      await syncEntitlement(uid);
      return;

    case "INITIAL_PURCHASE":
    case "RENEWAL": {
      const isTrial = ev.type === "INITIAL_PURCHASE" && ev.period_type === "TRIAL";
      const { active } = await syncEntitlement(uid, { trialStarted: isTrial });
      if (active && !ev.is_family_share) await admin.rpc("grant_premium_bonus", { p_uid: uid });
      return;
    }

    case "EXPIRATION":
      await syncEntitlement(uid, { lapsed: true });
      return;

    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "BILLING_ISSUE":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
    case "REFUND_REVERSED":
      await syncEntitlement(uid);
      return;

    default:
      console.log("ignored event type", ev.type);
  }
}

async function clawback(uid: string, productId: string, txn: string) {
  const { data: pack } = await admin.from("coin_packs").select("coins,bonus").eq("product_id", productId).maybeSingle();
  if (!pack) return;
  const { error } = await admin.rpc("credit_coins", {
    p_uid: uid, p_amount: -(pack.coins + pack.bonus), p_kind: "refund_clawback",
    p_key: `refund:${txn}`, p_meta: { product_id: productId },
  });
  if (error) throw error;
  // Policy: the balance may go negative. spend_coins blocks until it is positive again. Never delete unlocks.
}
```

```ts
// supabase/functions/sync-purchases/index.ts (JWT required)
import { createClient } from "jsr:@supabase/supabase-js@2";
import { creditPack, fetchSubscriber, syncEntitlement } from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const ent = await syncEntitlement(user.id);
  const sub = await fetchSubscriber(user.id);
  // VERIFY shape: non_subscriptions: { [product_id]: [{ id, store_transaction_id, purchase_date, is_sandbox }] }
  for (const [productId, txns] of Object.entries<any[]>(sub.non_subscriptions ?? {})) {
    for (const t of txns) {
      if (t.store_transaction_id) await creditPack(user.id, productId, t.store_transaction_id, { via: "sync" });
    }
  }
  const { data: wallet } = await userClient.from("coin_wallets").select("balance").maybeSingle();
  return Response.json({ premium: ent.active, expires_at: ent.expires, coins: wallet?.balance ?? 0 });
});
```

---

## Prompt M4 — Flutter purchase layer

```text
Goal: Build a clean purchase layer on purchases_flutter + Riverpod: configure, identify, offerings,
purchase, promo offers, restore, entitlement stream, coin wallet, and server sync. No UI in this phase
(only a debug screen behind kDebugMode).

Build:
- Add deps: purchases_flutter (latest stable; record the version), flutter_riverpod, supabase_flutter, intl.
  Read the CHANGELOG of the installed purchases_flutter major version. If purchase methods return
  PurchaseResult instead of CustomerInfo, or `purchasePackage` is deprecated in favor of
  `Purchases.purchase(PurchaseParams...)`, adapt the code below and note it.
- Identity: the user must have a Supabase session BEFORE the paywall. If onboarding runs before sign-in,
  call `supabase.auth.signInAnonymously()` at onboarding start, and link Apple/Google/email to the same uid
  later. Configure RevenueCat with appUserID = supabase uid. On auth change, call Purchases.logIn(uid).
  On sign-out, call Purchases.logOut() (only if not anonymous).
- PurchasesRepository: getPaywall(variant source), getExitOffer(), getWinback(), getCoinPacks(),
  buy(package), buyWithPromo(package, offerId), restore(), checkTrialEligibility(productIds).
- Domain models (pure Dart, testable): PremiumState, PaywallOffer, PlanOption, CoinPack, PurchaseOutcome
  (success | cancelled | pending | failed(code, message) | alreadyOwned).
- Providers: customerInfoProvider (StreamProvider), premiumProvider, paywallOfferProvider(trigger),
  coinBalanceProvider (Supabase realtime on coin_wallets, falling back to polling), limitsProvider (rpc get_limits).
- After every successful purchase or restore: call the `sync-purchases` function, then invalidate the wallet and limits.
- Price helpers: perWeek(annual) uses `storeProduct.pricePerWeekString` if it exists in the installed SDK
  (VERIFY); otherwise compute price / 52, rounding UP to 2 decimals so the price is never understated,
  formatted with NumberFormat.simpleCurrency(locale, name: currencyCode).
  savingsPercent = floor((1 - annual / (monthly * 12)) * 100). trialLabel comes from introductoryPrice.
- Error mapping: PurchasesErrorHelper.getErrorCode(PlatformException) → PurchaseOutcome.

Acceptance criteria:
- Unit tests: price helpers in en_US/USD and tr_TR/TRY, eligibility mapping, outcome mapping.
- Debug screen: shows the current offering id + metadata, packages with priceString, entitlement state,
  coin balance, and buttons to buy/restore in sandbox.
- Killing the app mid-purchase and relaunching restores the correct state (the listener fires).
- No price literal anywhere in lib/ (add a test that greps for currency symbols in lib/features/monetization).

Files to create:
lib/features/monetization/data/purchases_repository.dart
lib/features/monetization/data/wallet_repository.dart
lib/features/monetization/domain/{premium_state,paywall_offer,coin_pack,purchase_outcome}.dart
lib/features/monetization/domain/price_format.dart
lib/features/monetization/application/monetization_providers.dart
lib/features/monetization/application/revenuecat_bootstrap.dart
lib/features/monetization/presentation/debug_purchases_screen.dart
test/monetization/price_format_test.dart, test/monetization/outcome_mapping_test.dart
```

Key Dart (adapt to the installed SDK version; lines marked VERIFY):

```dart
// revenuecat_bootstrap.dart
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RevenueCatBootstrap {
  static Future<void> init() async {
    if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final config = PurchasesConfiguration(const String.fromEnvironment('RC_API_KEY_IOS'))
      ..appUserID = uid; // null => anonymous until logIn
    await Purchases.configure(config);

    Supabase.instance.client.auth.onAuthStateChange.listen((s) async {
      final id = s.session?.user.id;
      if (id != null && id != await Purchases.appUserID) {
        await Purchases.logIn(id);
      } else if (s.event == AuthChangeEvent.signedOut && !(await Purchases.isAnonymous)) {
        await Purchases.logOut();
      }
    });
  }
}
```

```dart
// monetization_providers.dart (excerpt)
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  final controller = StreamController<CustomerInfo>();
  void onUpdate(CustomerInfo info) => controller.add(info);
  Purchases.addCustomerInfoUpdateListener(onUpdate);
  Purchases.getCustomerInfo().then(controller.add, onError: controller.addError);
  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(onUpdate);
    controller.close();
  });
  return controller.stream;
});

final premiumProvider = Provider<PremiumState>((ref) {
  final info = ref.watch(customerInfoProvider).valueOrNull;
  final e = info?.entitlements.active[MonetizationIds.entitlement];
  if (e == null) return const PremiumState.free();
  return PremiumState(
    isActive: true,
    isTrial: e.periodType == PeriodType.trial,
    willRenew: e.willRenew,
    expiresAt: e.expirationDate == null ? null : DateTime.parse(e.expirationDate!),
    billingIssue: e.billingIssueDetectedAt != null,
    productId: e.productIdentifier,
  );
});
// UI uses premiumProvider for display. The server (is_premium) decides unlocks.
```

```dart
// purchases_repository.dart (excerpt)
class PurchasesRepository {
  Future<PaywallOffer> getPaywall() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null || current.annual == null || current.monthly == null) {
      throw const PaywallUnavailable();
    }
    final variant = (current.metadata['paywall_variant'] as String?) ?? 'timeline';
    final elig = await Purchases.checkTrialOrIntroductoryPriceEligibility(
        [current.annual!.storeProduct.identifier]);
    final trialEligible = elig[current.annual!.storeProduct.identifier]?.status ==
        IntroEligibilityStatus.introEligibilityStatusEligible;
    return PaywallOffer(
      offeringId: current.identifier,
      variant: variant,
      annual: current.annual!,
      monthly: current.monthly!,
      trialEligible: trialEligible && current.annual!.storeProduct.introductoryPrice?.price == 0,
    );
  }

  Future<Package?> getExitOffer() async {
    final o = (await Purchases.getOfferings()).all[MonetizationIds.offeringExit];
    final pkg = o?.annual;
    if (pkg == null) return null;
    final elig = await Purchases.checkTrialOrIntroductoryPriceEligibility([pkg.storeProduct.identifier]);
    final ok = elig[pkg.storeProduct.identifier]?.status ==
        IntroEligibilityStatus.introEligibilityStatusEligible;
    return ok ? pkg : null; // never show an offer the user cannot actually get
  }

  Future<PurchaseOutcome> buy(Package p) => _guard(() => Purchases.purchasePackage(p)); // VERIFY v9 API

  Future<PurchaseOutcome> buyWithPromo(Package p, String offerId) => _guard(() async {
        final discount = p.storeProduct.discounts?.firstWhere((d) => d.identifier == offerId);
        if (discount == null) throw const PromoUnavailable();
        final promo = await Purchases.getPromotionalOffer(p.storeProduct, discount); // VERIFY
        return Purchases.purchaseDiscountedPackage(p, promo);                         // VERIFY
      });

  Future<PurchaseOutcome> restore() => _guard(Purchases.restorePurchases);

  Future<PurchaseOutcome> _guard(Future<Object?> Function() run) async {
    try {
      await run();
      await Supabase.instance.client.functions.invoke('sync-purchases');
      return const PurchaseOutcome.success();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return switch (code) {
        PurchasesErrorCode.purchaseCancelledError => const PurchaseOutcome.cancelled(),
        PurchasesErrorCode.paymentPendingError => const PurchaseOutcome.pending(), // Ask to Buy
        PurchasesErrorCode.productAlreadyPurchasedError => const PurchaseOutcome.alreadyOwned(),
        _ => PurchaseOutcome.failed(code.name, e.message),
      };
    } on FunctionException {
      return const PurchaseOutcome.success(); // purchase succeeded; the webhook will catch up
    }
  }
}
```

```dart
// wallet_repository.dart (excerpt): spending is ALWAYS an RPC with a client idempotency key
Future<SpendResult> spend(String item, String ref) async {
  final key = const Uuid().v4(); // create ONCE per user intent; reuse it on retry
  final res = await _db.rpc('spend_coins', params: {
    'p_item': item, 'p_ref': ref, 'p_idempotency_key': key,
  }) as Map<String, dynamic>;
  return SpendResult.fromJson(res); // ok | insufficient(balance, cost) | premium_has_access | already_unlocked
}
```

---

## Prompt M5 — Plan ready, Paywall (A/B), Exit offer, Welcome

```text
Goal: Build the conversion screens from the prototype: "Plan ready" → Paywall (Timeline | Compare)
→ one-time exit offer → Welcome. Glass on controls only, solid content cards, and full
Reduce Transparency / Reduce Motion support. Open MyEx_Glass_Premium.html in a browser and match it.

Build:
1. Glass system (lib/ui/glass/):
   - reduceTransparencyProvider: iOS MethodChannel "myex/accessibility" →
     UIAccessibility.isReduceTransparencyEnabled + reduceTransparencyStatusDidChangeNotification.
     (Flutter's MediaQuery doesn't expose this flag; VERIFY in your Flutter version.)
   - reduceMotion = MediaQuery.disableAnimationsOf(context).
   - GlassSurface, GlassChip, GlassIconButton, GlassSheet (modal bottom sheet with a glass header + solid body),
     GlassDock (the bottom CTA area). Keep BackdropFilter count low: one per surface, never inside list items.
     VERIFY BackdropGroup / BackdropFilter.grouped availability for perf.
2. PlanReadyScreen: personalized from onboarding answers (breakup type, attachment style, focus,
   first win "Day 1 · 4 minutes"). A Lumi happy pose. CTA "See my plan" → Paywall(trigger: onboarding).
3. PaywallScreen(trigger):
   - Top bar: GlassIconButton close (X), visible immediately, plus a "Restore" text button.
   - Header: Lumi (crown) + "{name}, your plan for “{what}”" (serif, italic accent).
   - Variant "timeline": a 4-feature list → plan cards → trial timeline (Today / day trialDays-2 / day trialDays,
     with dates from DateFormat.MMMd(locale)). Variant "compare": a Free vs Premium table
     (Daily plan Day 1–3 vs All 30; Mira 3/day vs Unlimited; SOS + helplines ✓/✓; Draft Jail 1/day vs Unlimited;
     Analysis 1 insight vs Full; Bonus coins — vs 50/mo) → plan cards. No timeline in compare.
   - Plan cards (radio semantics): Annual preselected. Badge "{trial} days free · Save {pct}%"
     (show the trial part only if eligible). Each card shows the billed price ("{price} per year") AND the
     monthly-equivalent price as small text. Monthly card: "{price} per month", "No free trial".
   - "Remind me before my trial ends" switch (annual + eligible only), default ON. Stored locally and on the
     server (profiles.remind_trial if you add it). Used in M7.
   - Reassurance note: "Cancel in 2 taps in Settings. Your story never leaves your phone without your OK."
     (Only keep the second sentence if it is true for your data flow. Otherwise rewrite it.)
   - GlassDock: primary CTA (annual+eligible: "Start my {n} free days"; annual not eligible:
     "Subscribe for {annualPrice}/year"; monthly: "Subscribe for {monthlyPrice}/month"),
     fine print (copy section below), and links Restore · Terms · Privacy (open in SFSafariViewController).
   - States: skeleton while loading (no prices), an error card with Retry + "Continue with the free plan",
     a purchase-in-flight spinner on the CTA (disable double taps), pending (Ask to Buy) message, cancelled = no-op.
   - Analytics (M9): paywall_view{variant, trigger, offering_id}, plan_selected, purchase_* events.
4. Exit offer: on the FIRST close of any paywall, if not premium: call rpc mark_exit_offer_shown().
   Only if it returns true AND getExitOffer() returns an eligible package, show a GlassSheet:
   Lumi + "Before you go" + "Your first year, half price." + "{introPrice} for your first year instead of
   {annualPrice}." CTA "Claim 50% off" and text button
   "Continue with the free plan". Otherwise close straight to Home. Never show it again (the server flag).
5. WelcomeScreen (after any successful premium purchase): eyebrow "Free trial started" / "Premium unlocked",
   "Welcome in, {name}.", a list of what unlocked (All 30 days + Rebuild, Unlimited Mira, Full analysis,
   "50 bonus coins added" — shown only once the wallet confirms the credit, otherwise "on their way").
   If trial: "Free until {date}. We'll remind you on {date-2}." Ask for notification permission HERE
   (if remind = ON), not earlier. CTA → today's plan task (not a menu). Confetti only if !reduceMotion.
6. iOS AppDelegate: add the accessibility MethodChannel (Swift).

Acceptance criteria:
- With Reduce Transparency ON (Settings › Accessibility › Display & Text Size), there are zero blurs and every
  control stays legible. With Reduce Motion ON, there is no confetti or count-up.
- Turkish storefront sandbox shows ₺ prices from StoreKit, Turkish dates, and "%NN tasarruf".
- Not trial-eligible → no word "free" anywhere on the paywall.
- The X is tappable at first frame. The exit offer appears exactly once per account (test 2 devices).
- VoiceOver reads each plan card fully, and the selected state is announced.
- Golden tests for the paywall (both variants, light theme, reduced transparency on/off, EN/TR).

Files to create:
lib/ui/glass/{glass_surface,glass_chip,glass_icon_button,glass_sheet,glass_dock,accessibility_flags}.dart
lib/ui/theme/myex_tokens.dart (colors + text styles from M0)
lib/features/monetization/presentation/{plan_ready_screen,paywall_screen,exit_offer_sheet,welcome_screen}.dart
lib/features/monetization/presentation/widgets/{plan_card,trial_timeline,compare_table,paywall_fine_print}.dart
ios/Runner/AppDelegate.swift (channel), test/goldens/paywall_*.dart
```

```dart
// glass_surface.dart
class GlassSurface extends ConsumerWidget {
  const GlassSurface({super.key, required this.child, this.radius = 22,
      this.padding = const EdgeInsets.all(12), this.blur = 24});
  final Widget child; final double radius; final EdgeInsets padding; final double blur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(reduceTransparencyProvider);
    final r = BorderRadius.circular(radius);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: reduced ? MyExColors.surface : Colors.white.withValues(alpha: 0.62),
        border: Border.all(
            color: reduced ? MyExColors.hairline : Colors.white.withValues(alpha: 0.75), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x143A0F22), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (reduced) return box;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: box),
    );
  }
}
```

```swift
// AppDelegate.swift (inside didFinishLaunching, after GeneratedPluginRegistrant).
// VERIFY against your Flutter template; newer templates use FlutterImplicitEngineDelegate.
let controller = window?.rootViewController as! FlutterViewController
let channel = FlutterMethodChannel(name: "myex/accessibility", binaryMessenger: controller.binaryMessenger)
channel.setMethodCallHandler { call, result in
  call.method == "reduceTransparency"
    ? result(UIAccessibility.isReduceTransparencyEnabled) : result(FlutterMethodNotImplemented)
}
NotificationCenter.default.addObserver(
  forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil, queue: .main) { _ in
  channel.invokeMethod("reduceTransparencyChanged", arguments: UIAccessibility.isReduceTransparencyEnabled)
}
```

---

## Prompt M6 — Free limits, soft-limit sheets, coins

```text
Goal: Enforce the free tier on the server and present limits as calm, honest choices:
Premium / coins / wait. Build the Coins store. SOS is untouchable.

Build:
1. Server gate in supabase/functions/mira-chat/index.ts (existing function, so modify it):
   - Verify the JWT (auth.getUser). Read `conversation_id` and look up the conversation's origin SERVER-SIDE
     (the conversations.origin column is set when the conversation is created: 'sos' only if created via the
     SOS entry point). Never accept origin from the message body.
   - Call rpc consume_quota(uid, 'message', origin) with the service role BEFORE calling the LLM.
     If allowed=false → HTTP 402 with JSON {code:'limit', resets_at}. If the LLM call fails →
     rpc refund_message(uid, via).
   - If origin='sos': use the crisis-safe system prompt (grounding, no romance advice, surface helplines
     [HELPLINE_TR]/[HELPLINE_US] when risk language appears). This also neutralizes abuse of SOS as an
     "unlimited" loophole, without ever limiting it.
   - Same pattern for Draft Jail (consume_quota(uid,'draft')).
2. Client Coach screen:
   - Meter (dots) showing free messages left, from rpc get_limits (display only). Hidden for premium and in SOS chats.
   - On HTTP 402 → LimitSheet (GlassSheet): Mira avatar, "Mira is still here.",
     "You've used today's 3 free messages. Pick what works for you:"
       a) primary: "Talk without limits" / sub "Premium · {n} days free" → Paywall(trigger: coach_limit)
       b) glass: "20 more messages · 10 coins" (if balance ≥ 10) else "Get coins for more messages" → Coins store
       c) text: "Wait until {resetTime}" (09:00 local, formatted with DateFormat.jm(locale))
       d) small link: "Need help right now? Open SOS" (always present, free)
     The unsent message text stays in the composer and is never lost.
3. Plan: locked days 4–30 render as locked cards with title + promise (teaser table). Tap → LockDaySheet:
   "Unlock all 30 days" (Premium, trigger plan_lock) and "Unlock Day {d} only · 15 coins".
4. Analysis: 1 real insight free, the others are blurred placeholders (the locked text is NEVER sent to the client).
   Dock: "Unlock everything · {n} days free" + "Unlock this analysis · 30 coins".
5. Coins store screen: balance, 3 packs from offering "coins" (priceString only; the "Popular" and "Best value"
   tags come from offering metadata), a "What coins unlock" list (prices from the coin_catalog table, not literals),
   and for free users a cross-sell note "Premium members get 50 free coins every month." → Paywall(trigger: coins).
   After buying: show "Adding coins…" until wallet realtime/poll confirms (timeout 20s → "Your coins are on the
   way. Pull to refresh." and call sync-purchases).
6. spend flow: generate the idempotency key once per user intent → rpc spend_coins → on ok, apply the
   unlock + a toast + an animated count (only if !reduceMotion). On insufficient → open the Coins store with the
   needed amount highlighted. On premium_has_access → refresh entitlement.
7. Premium UI: the Home "Premium" glass chip for free users, coin chip for everyone, and status not pop-ups
   (prototype Home "why"). No automatic paywall pop-ups except at onboarding.

Acceptance criteria:
- A free user sends 3 messages → the 4th returns 402 and the sheet opens. A reset at 09:00 local is verified by
  changing the server clock in a test, not the device clock.
- 50 messages from an SOS conversation: all answered, messages_used unchanged, and no sheet ever appears.
- Patching the client to skip the sheet still returns 402 from the server.
- Double-tapping "Unlock Day 5" spends 15 coins once.
- A coin purchase in sandbox → balance updates within seconds with no app restart.
- No paywall, coin, or premium element is reachable from the SOS screen or the crisis sheet (widget test).

Files to create/modify:
supabase/functions/mira-chat/index.ts (modify), supabase/functions/draft-jail/index.ts (modify)
supabase/migrations/<ts>_conversation_origin.sql (conversations.origin text check in ('normal','sos'))
lib/features/monetization/presentation/{limit_sheet,lock_day_sheet,coins_store_screen}.dart
lib/features/monetization/presentation/widgets/{coin_chip,message_meter,coin_count}.dart
test/monetization/sos_never_paywalled_test.dart
```

```ts
// mira-chat/index.ts: the gate (excerpt)
const { data: conv } = await admin.from("conversations")
  .select("id, origin, user_id").eq("id", body.conversation_id).single();
if (!conv || conv.user_id !== user.id) return new Response("not found", { status: 404 });

const { data: q, error } = await admin.rpc("consume_quota",
  { p_uid: user.id, p_kind: "message", p_origin: conv.origin });
if (error) return new Response("quota error", { status: 500 });
if (!q.allowed) return Response.json({ code: "limit", resets_at: q.resets_at }, { status: 402 });

try {
  const reply = await callLLM({ system: conv.origin === "sos" ? SOS_SYSTEM_PROMPT : COACH_SYSTEM_PROMPT, ... });
  return Response.json({ reply, quota: q });
} catch (e) {
  if (q.counted) await admin.rpc("refund_message", { p_uid: user.id, p_via: q.via });
  throw e;
}
```

---

## Prompt M7 — Trial reminders, Trial status, Win-back

```text
Goal: Keep the promise made on the paywall ("we remind you 2 days before"), show visible value during
the trial, and bring lapsed users back with an honest App Store promotional offer.

Build:
1. Value recap RPC get_value_recap() (security definer, auth.uid()): talks (Mira conversations since
   trial_started_at or in the last 30 days), drafts_not_sent (Draft Jail drafts that expired without
   being sent), days_done (plan days completed), streak_days. ADAPT the table names, and ask me if unsure.
2. Local reminder (flutter_local_notifications + timezone):
   - Schedule when the trial starts (if remind ON and permission granted):
     fireAt = entitlement expiresAt − 48h, clamped to 10:00–20:00 local.
   - Reschedule on every app foreground with fresh recap numbers (cancel + re-add the same id), because
     the recap text is baked in at schedule time.
   - Cancel it when the trial converts, is cancelled (willRenew=false: change the copy to "Your Premium ends
     on {date}"), or expires.
   - Tapping it deep-links to the Trial status screen.
   - Record `profiles.trial_reminder_local_at` (add the column) so the server knows a local one exists.
3. Server push backup: supabase/functions/lifecycle-push (cron hourly via pg_cron + pg_net, or Supabase
   Cron → function invoke). Sends via [PROVIDER].
   - trial_reminder: premium_period_type='trial' AND expires in 46–50h AND no notification_log row for
     this trial AND (trial_reminder_local_at is null OR the user hasn't opened the app in 72h).
   - winback: premium_lapsed_at between 7 and 14 days ago AND not premium AND winback not sent yet.
   - A notification_log(user_id, kind, ref, sent_at, unique(user_id, kind, ref)) table guarantees one send.
   - Localized EN/TR by profiles.locale. Respect quiet hours (no push 21:00–09:00 local).
4. TrialStatusScreen: a ring showing days left (static if reduceMotion), "Free until {date}", the value recap
   cards (talks, drafts not sent, days done), what happens next ("On {date} you'll be charged {price}/year
   unless you cancel"), primary "Keep Premium" (dismiss), and a secondary "Manage subscription" (opens the hub).
   The cancel path must be visible here, not hidden.
5. WinbackScreen (shown once on app open when lapsed 7–14 days, or from the push):
   - Lead with what they kept: "Your streak, journal and plan are saved."
   - Offer card: promotional offer "winback_3m" on the monthly package from offering "winback":
     "{promoPrice} for 3 months of Premium, then {monthlyPrice}/month" (both strings from StoreKit:
     the discount's priceString + the product priceString).
   - One CTA "Come back for {promoPrice}" + one "No thanks". Mark winback_shown_at on the server.
   - If getPromotionalOffer fails (not eligible / no key), fall back to the normal paywall (trigger: winback)
     without mentioning a discount.
   - Optional: Apple win-back offers (iOS 18+) through RevenueCat. VERIFY SDK support, and don't double-offer.
6. BillingIssueBanner on Home + the hub when premium_billing_issue_at is set: "There's a problem with your
   payment. Update it in the App Store to keep Premium." → manage subscriptions URL. No guilt copy.

Acceptance criteria:
- A sandbox annual trial (shortened in sandbox: verify the current sandbox renewal rates) → the local
  notification fires at the clamped time with real numbers. Reinstalling the app → the server push fires instead.
- Turning the "remind me" toggle OFF → no local reminder. The server backup still respects it (store the flag server-side).
- The win-back offer is never shown to a currently-premium user, a never-subscribed user, or twice.

Files to create:
lib/features/monetization/application/trial_reminder_service.dart
lib/features/monetization/presentation/{trial_status_screen,winback_screen,billing_issue_banner}.dart
supabase/functions/lifecycle-push/index.ts
supabase/migrations/<ts>_lifecycle.sql (get_value_recap, notification_log, remind_trial, trial_reminder_local_at, cron)
```

---

## Prompt M8 — Subscription hub in "Me" + cancel survey

```text
Goal: "Me" doubles as the subscription hub. Subscribers see status, the renewal date, and an easy cancel.
Cancel opens a 1-question survey that answers each reason and NEVER blocks the exit.

Build:
1. SubscriptionHubSection in the Me screen:
   - Free: a calm upgrade card "Get Premium" + "{n} days free" (only if eligible) + "All 30 days, unlimited
     Mira, full analysis." → Paywall(trigger: me).
   - Trial: "Free trial · day {d} of {n}", "Free until {date}", link to Trial status.
   - Premium: plan name (Annual/Monthly), "Renews {date}" or "Ends {date}" (willRenew=false),
     a billing-issue banner, coin balance + "Get coins", Restore purchases, Manage subscription, Cancel subscription,
     Contact support [SUPPORT_EMAIL], Terms, Privacy.
2. Manage/Cancel destination: CustomerInfo.managementURL if present, else
   https://apps.apple.com/account/subscriptions (url_launcher, external app). VERIFY whether the installed
   purchases_flutter exposes a native manage-subscriptions sheet, and prefer it if so.
3. CancelSurveySheet ("Before you go, what's the reason?") with chips: Too expensive · I feel better now ·
   I'm not using it · Something else. "Continue to cancel" is a visible text button from the first frame
   (danger color) that ALWAYS opens the manage URL, with or without a selected reason.
   Reason replies:
   - price → card "Stay for {promoPrice} for the next year. Half price, same everything. Applied as an
     App Store offer." CTA "Keep Premium for less" → buyWithPromo(annual package, 'save50_annual').
     Only for annual subscribers where the promo discount exists. Monthly subscribers: offer the switch to
     annual instead (show the real savings %) or no offer. Never use the intro product here (current subscribers
     aren't eligible).
   - better → Lumi celebrating: "That's the whole point. Your streak, journal and SOS stay free forever.
     Come back anytime." (no offer)
   - unused → "Want a gentle nightly check-in? One short message from Mira at 22:00." CTA "Turn on check-ins"
     (a local daily notification at 22:00; asks permission if needed). Don't claim usage multipliers unless measured.
   - other → "Thank you for telling us. It helps us make MyEx better." + an optional 500-char note.
   Insert a row into cancel_survey_responses (reason, offer_shown, offer_accepted). Fire analytics cancel_reason.
4. After returning from Settings: refresh CustomerInfo + sync-purchases, and show "Premium stays on until {date}"
   if cancelled. Don't nag.

Acceptance criteria:
- From the hub, a user can reach the App Store cancel page in ≤ 2 taps without selecting a reason.
- The price offer only appears when the promotional offer is actually available for that user/product.
- All texts are EN/TR and dates are locale-formatted.

Files to create:
lib/features/monetization/presentation/{subscription_hub_section,cancel_survey_sheet}.dart
lib/features/monetization/application/manage_subscription.dart
lib/features/checkins/nightly_checkin_service.dart
```

---

## Prompt M9 — Analytics, experiments, KPIs

```text
Goal: Instrument the whole funnel with one typed analytics API, wire server-side subscription truth,
and run the paywall A/B test properly.

Build:
1. lib/core/analytics/analytics.dart: a typed facade over [ANALYTICS_PROVIDER] (one method per event, no
   free-form strings in feature code). Identify the user with the Supabase uid (the same as the RevenueCat
   app user id). No PII and no journal/chat content in properties. Respect App Tracking Transparency
   (no IDFA, no ATT prompt needed for first-party analytics; VERIFY with your provider's settings).
   Set RevenueCat subscriber attributes for the analytics id if you use the RC integration (VERIFY attribute names).
2. Client events (props in braces; always include locale, app_version, is_premium):
   onboarding_completed{breakup_type}
   plan_ready_view
   paywall_view{variant, trigger, offering_id, trial_eligible}   trigger ∈ onboarding|home_chip|plan_lock|
       coach_limit|analysis_lock|coins|me|trial_status|winback|deep_link
   paywall_closed{variant, trigger, time_on_screen_ms}
   plan_selected{product_id, variant}
   remind_toggle{on}
   purchase_started{product_id, offering_id, trigger, variant}
   purchase_completed{product_id, offering_id, trigger, variant, is_trial}
   purchase_cancelled{product_id, trigger}      purchase_failed{product_id, error_code}
   purchase_pending{product_id}
   restore_tapped / restore_completed{found}
   exit_offer_shown / exit_offer_claimed / exit_offer_dismissed
   limit_hit{kind: message|draft|plan_day|analysis, free_used}
   limit_sheet_action{kind, action: premium|coins|wait|sos}
   coins_store_view{source}   coins_purchased{product_id, coins}   coins_spent{item, cost, balance_after}
   trial_status_view{days_left}   winback_shown / winback_claimed / winback_dismissed
   cancel_survey_shown   cancel_reason{reason, offer_shown}   cancel_offer_accepted{reason}
   manage_subscription_opened{source}
   sos_opened{from}  (for safety monitoring only, never used for targeting)
3. Server truth (don't fire these from the client): trial_started, trial_converted, trial_cancelled, renewal,
   expiration, refund, billing_issue. Use the RevenueCat → [ANALYTICS_PROVIDER] integration, OR emit from the
   webhook (map INITIAL_PURCHASE+TRIAL → trial_started; RENEWAL with is_trial_conversion=true → trial_converted
   (VERIFY the field); CANCELLATION during a trial → trial_cancelled; CANCELLATION cancel_reason CUSTOMER_SUPPORT → refund).
   Filter environment = SANDBOX out of dashboards.
4. Experiments:
   - Default: RevenueCat Experiments with offerings "default" (timeline) vs "default_compare" (compare),
     new customers only, 50/50. The client reads offerings.current.metadata.paywall_variant, so no app release
     is needed to change variants.
   - Fallback without Experiments: a Supabase remote_config table + a deterministic bucket hash(uid) % 100.
     Log the variant on paywall_view either way.
   - Primary metric: revenue (or realized LTV proxy) per paywall viewer at 14+ days. Secondary: trial start
     rate, trial→paid. Pre-register: duration ≥ 2 full weeks AND a minimum sample (decide before starting);
     don't stop early on a good day. One experiment at a time on the main paywall.
5. docs/monetization/KPIS.md: definitions, formulas and where each comes from:
   - install → trial start % (by trigger + variant)
   - trial → paid % (cohort by trial start week)
   - paywall CVR by trigger = purchases_completed / paywall_view, per trigger
   - exit offer take rate and its cannibalization of full-price annual
   - ARPU (revenue / installs, cohort D30 + D90) and ARPPU
   - D1 / D7 / D30 retention for free vs trial vs paid
   - refund rate (refunds / paid transactions) and chargeback signals
   - coin attach rate (% of non-subscribers buying coins), coins spent per item
   - cancel reasons distribution and offer save rate
   - SOS usage (safety metric, never a monetization lever)
   Note: typical benchmarks vary widely by category and price; treat any public benchmark as directional and
   compare against your own cohorts.

Acceptance criteria:
- Every event above fires exactly once per action (verified with the provider's live debugger).
- No chat/journal/draft text in any analytics payload (a test asserts property allowlists).
- The variant is visible on paywall_view and purchase_completed for the same session.

Files to create:
lib/core/analytics/{analytics.dart,events.dart}
docs/monetization/KPIS.md, docs/monetization/EXPERIMENTS.md
supabase/migrations/<ts>_remote_config.sql (only if not using RevenueCat Experiments)
```

---

## Prompt MR — Monetization review (adversarial)

```text
Act as an adversarial reviewer (App Review + a payments security engineer + an ethics reviewer). Review the
whole monetization implementation against M0–M9. Do not fix anything yet. Produce
docs/monetization/REVIEW.md with findings ranked Blocker / High / Medium / Low, each with file:line, the repro,
and the fix. Then ask me which ones to fix.

Run or check every item:

Sandbox & purchase paths
[ ] Fresh install, sandbox tester EN + TR storefront: annual trial, monthly, exit offer, coins ×3, win-back promo.
[ ] Use the StoreKit config file in Xcode for interrupted purchases, Ask to Buy (pending → approved/declined),
    and failed transactions. Verify each UI state.
[ ] Sandbox renewals are accelerated (verify the current rates). Watch 6 renewals → RENEWAL webhooks →
    monthly bonus granted once per calendar month.
[ ] Trial eligibility: a sandbox tester who already used the trial sees no "free" wording anywhere, and the exit
    offer is NOT shown.
[ ] Restore: on a new device / after reinstall, the entitlement comes back. The coin balance comes back because it
    lives on the server (consumables are not restorable by StoreKit, and the copy must not promise that).
[ ] Account switch: user A buys, signs out, user B signs in on the same device. Check Purchases.logIn/logOut,
    the TRANSFER webhook, and that both profiles mirror correctly. Document the transfer behavior setting.
[ ] Offline / airplane mode: paywall error state, no crash, "Continue free" works.

Server security
[ ] Webhook: wrong/missing auth → 401. Replayed event → no double credit. Out-of-order events → final state correct.
[ ] Forged client calls: authenticated user calls credit_coins / consume_quota / grant_premium_bonus →
    permission denied. Direct UPDATE of profiles.premium_expires_at or message_credits → denied.
[ ] spend_coins race: 50 parallel calls → the balance never goes below 0 (except clawback). Idempotent retries.
[ ] mira-chat: origin comes only from the DB. A client claiming "sos" in the body has no effect.
    Limit enforced at 402 with the client sheet bypassed.
[ ] Timezone abuse: changing tz repeatedly to reset the counter → blocked by the 24h guard.
[ ] Locked plan days / analysis text never present in API responses for free users (inspect the network).
[ ] No secrets in the app bundle (strings scan of the .ipa for "sk_", the service role key, the webhook token).

Lifecycle
[ ] Refund (production: CANCELLATION with CUSTOMER_SUPPORT; test with StoreKit testing in Xcode):
    the subscription is revoked on the server, coin clawback is applied, unlocked content stays (no punishment UI).
[ ] Billing issue → banner shown. Grace period → premium stays active until grace ends. Recovery → banner gone.
[ ] Cancellation during the trial → hub shows "Ends {date}", the reminder copy changes, access lasts until the end.
[ ] Family Sharing: if ON, is_family_share access works, gets no bonus coins, and the hub copy is correct.
    If OFF, confirm in ASC.
[ ] Price increase / StoreKit messages: the app doesn't suppress Apple's price-consent sheet.
[ ] Win-back: only lapsed users, 7–14 days, once. Promo signature works (In-App Purchase Key uploaded).

Compliance & ethics (Guidelines 3.1.1, 3.1.2, 5.1.1)
[ ] The paywall shows the title, length, billed price, trial terms, renewal terms, Terms (EULA) + Privacy links,
    Restore. The billed price is the main price; no per-week price appears.
[ ] Close is visible at first frame. No countdowns, fake scarcity, fake reviews, or pre-checked upsells.
[ ] "We only show this once" is true (the server flag).
[ ] SOS + crisis helplines: no paywall, limit, coin or premium UI reachable from them. Helpline numbers are correct
    per locale.
[ ] Coins never expire, and no copy implies they do. Coins are only used for digital content.
[ ] The cancel path is never blocked or hidden. The survey is skippable at first frame.
[ ] All strings are localized EN/TR. Prices/dates come from StoreKit/intl, and no hardcoded currency appears anywhere.
[ ] Accessibility: VoiceOver on the paywall + sheets, Dynamic Type XXL, Reduce Transparency, Reduce Motion.

App Review notes (draft them in REVIEW.md for App Store Connect › App Review Information)
- Demo account credentials (or "sign in with Apple, no account needed").
- Where to find the paywall (after onboarding, or Me › Get Premium), Restore location, Coins (Me › Coins).
- "SOS and crisis resources are always free and never behind a paywall."
- "Mira is an AI coach, not a medical or therapy service" + the moderation/safety approach.
- Subscriptions + consumables submitted with this binary. Each has a review screenshot.
```

---

## Paywall copy (EN / TR)

Use these as the ARB values. `{…}` are placeholders filled from StoreKit/intl or user data. Turkish uses the informal "sen", which fits the app's warm tone. In Turkish, the percent sign comes first (`%40`). Turkish has no plural agreement after numbers ("3 mesaj"), but English needs ICU plurals.

| Key | English | Türkçe |
|---|---|---|
| planReady.eyebrow | Made for you, {name} | {name}, senin için hazırlandı |
| planReady.title | Your plan is *ready.* | Planın *hazır.* |
| planReady.cta | See my plan | Planımı gör |
| paywall.eyebrow | {name}, your plan for | {name}, planın şunun için: |
| paywall.headline | “{what}”, *30 days to feel like you again.* | “{what}”, *30 günde yeniden kendin gibi hisset.* |
| paywall.feature.mira | Mira, every night · Unlimited talks, even at 2am | Mira, her gece · Sınırsız sohbet, gece 2'de bile |
| paywall.feature.plan | All 30 days + Rebuild stage · Free plan stops at Day 3 | 30 günün tamamı + Yeniden Kurulum · Ücretsiz plan 3. günde biter |
| paywall.feature.analysis | Full relationship analysis · See the patterns you missed | Tam ilişki analizi · Gözden kaçırdığın kalıpları gör |
| paywall.feature.coins | 50 bonus coins every month | Her ay 50 hediye jeton |
| paywall.annual | Annual | Yıllık |
| paywall.annual.billed | {price} per year | Yıllık {price} |
| paywall.annual.badge | {days} days free · Save {pct}% | {days} gün ücretsiz · %{pct} tasarruf |
| paywall.perMonthEquivalent | {price}/month | Aylık {price} |
| paywall.monthly | Monthly | Aylık |
| paywall.monthly.billed | {price} per month | Aylık {price} |
| paywall.monthly.noTrial | No free trial | Ücretsiz deneme yok |
| paywall.timeline.today | Today · Everything unlocks. You pay nothing. | Bugün · Her şey açılır. Hiçbir şey ödemezsin. |
| paywall.timeline.remind | {date} · We remind you 2 days before it ends. | {date} · Bitmeden 2 gün önce sana hatırlatırız. |
| paywall.timeline.end | {date} · Trial ends. {price}/year, unless you cancel before. | {date} · Deneme biter. Önceden iptal etmezsen yıllık {price}. |
| paywall.remindToggle | Remind me before my trial ends | Deneme bitmeden bana hatırlat |
| paywall.note | Cancel in 2 taps in Settings. | Ayarlar'dan 2 dokunuşla iptal edebilirsin. |
| paywall.cta.trial | Start my {days} free days | {days} günlük ücretsiz denememi başlat |
| paywall.cta.annual | Subscribe for {price}/year | Yıllık {price} ile abone ol |
| paywall.cta.monthly | Subscribe for {price}/month | Aylık {price} ile abone ol |
| paywall.fine.trial | Free for {days} days, then {price}/year. Cancel anytime. | {days} gün ücretsiz, ardından yıllık {price}. İstediğin zaman iptal et. |
| paywall.fine.monthly | Renews monthly. Cancel anytime. | Her ay yenilenir. İstediğin zaman iptal et. |
| paywall.fine.legal | Payment is charged to your Apple ID when you confirm (or when the free trial ends). The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings › Apple ID › Subscriptions. | Ödeme, onayladığında (veya ücretsiz deneme bittiğinde) Apple ID hesabından alınır. Abonelik, mevcut dönem bitmeden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir. Ayarlar › Apple ID › Abonelikler'den yönetebilir veya iptal edebilirsin. |
| paywall.links | Restore · Terms · Privacy | Geri Yükle · Koşullar · Gizlilik |
| paywall.error | We couldn't load the plans. | Planlar yüklenemedi. |
| common.retry / continueFree | Try again / Continue with the free plan | Tekrar dene / Ücretsiz planla devam et |
| exit.eyebrow | Before you go | Gitmeden önce |
| exit.title | Your first year, *half price.* | İlk yılın *yarı fiyatına.* |
| exit.body | {offer} for your first year instead of {annual}. | İlk yılın için {annual} yerine {offer}. |
| exit.cta | Claim 50% off | %50 indirimi al |
| exit.dismiss | Continue with the free plan | Ücretsiz planla devam et |
| welcome.eyebrow.trial / .paid | Free trial started / Premium unlocked | Ücretsiz deneme başladı / Premium açıldı |
| welcome.title | Welcome in, *{name}.* | Hoş geldin, *{name}.* |
| welcome.body | Everything is open. Lumi is proud of you for choosing yourself. | Her şey açık. Lumi kendini seçtiğin için seninle gurur duyuyor. |
| welcome.trialNote | Free until {date}. We'll remind you on {remindDate}. | {date} tarihine kadar ücretsiz. {remindDate} tarihinde sana hatırlatacağız. |
| limit.title | Mira is still *here.* | Mira hâlâ *burada.* |
| limit.body | You've used today's 3 free messages. Pick what works for you: | Bugünkü 3 ücretsiz mesajını kullandın. Sana uyanı seç: |
| limit.premium | Talk without limits · Premium · {days} days free | Sınırsız konuş · Premium · {days} gün ücretsiz |
| limit.coins | 20 more messages · 10 coins | 20 mesaj daha · 10 jeton |
| limit.getCoins | Get coins for more messages | Daha fazla mesaj için jeton al |
| limit.wait | Wait until {time} | Saat {time}'e kadar bekle |
| limit.sos | Need help right now? Open SOS | Şu an yardıma mı ihtiyacın var? SOS'u aç |
| lockDay.premium | Unlock all 30 days · {days} days free | 30 günün tamamını aç · {days} gün ücretsiz |
| lockDay.coins | Unlock Day {d} only · 15 coins | Sadece {d}. günü aç · 15 jeton |
| lockDay.freeNote | Free covers Days 1–3. Premium opens all 30, plus the Rebuild stage. | Ücretsiz plan 1–3. günleri kapsar. Premium 30 günün tamamını ve Yeniden Kurulum aşamasını açar. |
| analysis.premium | Unlock everything · {days} days free | Her şeyi aç · {days} gün ücretsiz |
| analysis.coins | Unlock this analysis · 30 coins | Bu analizi aç · 30 jeton |
| coins.crossSell | Premium members get 50 free coins every month. | Premium üyelere her ay 50 jeton hediye. |
| coins.adding | Adding your coins… | Jetonların ekleniyor… |
| trialReminder.title | Your free trial ends in 2 days | Ücretsiz denemen 2 gün sonra bitiyor |
| trialReminder.body | {talks} talks with Mira, {drafts} texts you didn't send, {days} days done. Keep going for {price}/year, or cancel anytime in Settings. | Mira ile {talks} sohbet, göndermediğin {drafts} mesaj, tamamlanan {days} gün. Yıllık {price} ile devam et ya da istediğin zaman Ayarlar'dan iptal et. |
| winback.title | Welcome back. Your streak, journal and plan are saved. | Tekrar hoş geldin. Serin, günlüğün ve planın kayıtlı. |
| winback.offer | {promo} for 3 months of Premium, then {monthly}/month | 3 ay Premium {promo}, ardından aylık {monthly} |
| winback.cta / no | Come back for {promo} / No thanks | {promo} ile geri dön / Hayır, teşekkürler |
| cancel.title | Before you go, *what's the reason?* | Gitmeden önce, *sebebi ne?* |
| cancel.reasons | Too expensive · I feel better now · I'm not using it · Something else | Çok pahalı · Artık daha iyiyim · Kullanmıyorum · Başka bir sebep |
| cancel.price | Stay for {promo} for the next year. Half price, same everything. Applied as an App Store offer. · Keep Premium for less | Önümüzdeki yıl için {promo} ile kal. Yarı fiyat, her şey aynı. App Store teklifi olarak uygulanır. · Premium'u daha uygun fiyata koru |
| cancel.better | That's the whole point. Your streak, journal and SOS stay free forever. Come back anytime. | Amaç da buydu. Serin, günlüğün ve SOS her zaman ücretsiz kalır. İstediğin zaman geri gel. |
| cancel.unused | Want a gentle nightly check-in? One short message from Mira at 22:00. · Turn on check-ins | Her gece nazik bir hatırlatma ister misin? Saat 22:00'de Mira'dan kısa bir mesaj. · Hatırlatmaları aç |
| cancel.other | Thank you for telling us. It helps us make MyEx better. | Bize anlattığın için teşekkürler. MyEx'i daha iyi yapmamıza yardımcı oluyor. |
| cancel.continue | Continue to cancel | İptale devam et |
| hub.renews / ends | Renews {date} / Ends {date} | {date} tarihinde yenilenir / {date} tarihinde sona erer |
| hub.billingIssue | There's a problem with your payment. Update it in the App Store to keep Premium. | Ödemende bir sorun var. Premium'u korumak için App Store'dan güncelle. |
| sos.crisis.title | You matter. *Help is here.* | Sen değerlisin. *Yardım burada.* |
| sos.crisis.body | If you might hurt yourself, please reach a real person now. | Kendine zarar verebileceğini düşünüyorsan, lütfen hemen gerçek bir insana ulaş. |

*Asterisks mark the italic serif accent (`<em>` in the prototype). Have a native Turkish speaker proofread before release, especially the legal fine print. Apple's own subscription screens use "Abonelikler".*
