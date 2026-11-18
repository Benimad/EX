-- =============================================================================
-- MyEx monetization schema (Prompt M2, adapted). Server-authoritative:
-- entitlement mirror, coin wallet + ledger, usage counters (09:00 local reset),
-- content unlocks, webhook log, cancel survey, RPCs, monthly bonus cron.
-- UNTESTED: written without the Supabase CLI. Run `supabase db reset` locally
-- and supabase/tests/monetization_test.sql before deploying.
-- Adaptations vs M2 are marked "ADAPTED".
-- =============================================================================

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
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
drop policy if exists profiles_update_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Column-level privileges: clients may only edit harmless columns.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (timezone, locale, no_contact_since, remind_trial) on public.profiles to authenticated;

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

drop policy if exists coin_packs_read on public.coin_packs;
create policy coin_packs_read on public.coin_packs   for select to authenticated using (true);
drop policy if exists coin_catalog_read on public.coin_catalog;
create policy coin_catalog_read on public.coin_catalog for select to authenticated using (true);
drop policy if exists wallet_read_own on public.coin_wallets;
create policy wallet_read_own on public.coin_wallets for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists ledger_read_own on public.coin_ledger;
create policy ledger_read_own on public.coin_ledger  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists unlocks_read_own on public.content_unlocks;
create policy unlocks_read_own on public.content_unlocks for select to authenticated using ((select auth.uid()) = user_id);
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
drop policy if exists usage_read_own on public.usage_counters;
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
  v_tz := coalesce(v_tz, 'UTC');                        -- ADAPTED: profile row may be missing
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
revoke execute on function public.get_limits() from public, anon;
grant execute on function public.get_limits() to authenticated;

-- ============ PLAN CONTENT GATING (adapt to your plan table) ============
-- Example: content for days 4–30 must never reach a free client.
-- drop policy if exists plan_days_read on public.plan_days;
create policy plan_days_read on public.plan_days for select to authenticated using (
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
revoke execute on function public.mark_exit_offer_shown() from public, anon;
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
drop policy if exists cancel_insert_own on public.cancel_survey_responses;
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
create extension if not exists pg_cron;
select cron.schedule('monthly-premium-bonus', '15 6 * * *', $$select public.grant_monthly_bonuses();$$);
-- Daily at 06:15 UTC. It is idempotent, so a missed day self-heals.


-- ADAPTED: wallets for users created before this migration ran, and on signup.
insert into public.coin_wallets (user_id) select id from public.profiles on conflict do nothing;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  insert into public.coin_wallets (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ADAPTED: one-time + content flags read by the client meter/welcome screen.
revoke execute on function public.usage_day_for(text, timestamptz) from public, anon;
grant execute on function public.usage_day_for(text, timestamptz) to authenticated, service_role;

-- ADAPTED: index FKs used by RLS lookups.
create index if not exists cancel_survey_user_idx on public.cancel_survey_responses (user_id);

-- ADAPTED: live coin balance in the app (Supabase Realtime, RLS applies).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables
                     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'coin_wallets') then
    alter publication supabase_realtime add table public.coin_wallets;
  end if;
end $$;
