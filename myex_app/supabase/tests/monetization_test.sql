-- =============================================================================
-- Monetization SQL tests (plain DO blocks + ASSERT, no pgTAP needed).
-- UNTESTED. Run against a LOCAL database after `supabase db reset`:
--   psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" -f supabase/tests/monetization_test.sql
-- Everything runs in one transaction and is rolled back.
-- The 50-parallel spend_coins race test needs pgbench; see README "Manual tests".
-- =============================================================================
begin;

-- Two test users.
insert into auth.users (id, instance_id, aud, role, email)
values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.local'),
       ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local');

-- Helper: act as user A (authenticated role + JWT sub claim).
create or replace function pg_temp.as_user(p uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

-- 1) Profile + wallet are created by the signup trigger.
do $$ begin
  assert exists (select 1 from public.profiles where id = '00000000-0000-0000-0000-0000000000a1'), 'profile missing';
  assert exists (select 1 from public.coin_wallets where user_id = '00000000-0000-0000-0000-0000000000a1'), 'wallet missing';
end $$;

-- 2) credit_coins twice with the same key credits once (service role context = current superuser).
do $$ declare r jsonb; b int; begin
  r := public.credit_coins('00000000-0000-0000-0000-0000000000a1', 30, 'purchase', 'iap:T1');
  r := public.credit_coins('00000000-0000-0000-0000-0000000000a1', 30, 'purchase', 'iap:T1');
  assert (r->>'duplicate')::boolean, 'second credit should be duplicate';
  select balance into b from public.coin_wallets where user_id = '00000000-0000-0000-0000-0000000000a1';
  assert b = 30, format('balance %s, expected 30', b);
end $$;

-- 3) usage_day_for flips at 09:00 local.
do $$ begin
  assert public.usage_day_for('Europe/Istanbul', '2026-03-10 05:59:00+00') = '2026-03-09', 'IST before 09:00';
  assert public.usage_day_for('Europe/Istanbul', '2026-03-10 06:00:00+00') = '2026-03-10', 'IST at 09:00';
  assert public.usage_day_for('America/New_York', '2026-07-10 12:59:00+00') = '2026-07-09', 'NY before 09:00 (EDT)';
  assert public.usage_day_for('America/New_York', '2026-07-10 13:00:00+00') = '2026-07-10', 'NY at 09:00 (EDT)';
end $$;

-- 4) consume_quota: 3 free, 4th blocked; SOS never counts and is never blocked.
do $$ declare r jsonb; i int; used int; begin
  for i in 1..3 loop
    r := public.consume_quota('00000000-0000-0000-0000-0000000000a1', 'message', 'normal');
    assert (r->>'allowed')::boolean, 'free message should be allowed';
  end loop;
  r := public.consume_quota('00000000-0000-0000-0000-0000000000a1', 'message', 'normal');
  assert not (r->>'allowed')::boolean, '4th message must be blocked';
  for i in 1..50 loop
    r := public.consume_quota('00000000-0000-0000-0000-0000000000a1', 'message', 'sos');
    assert (r->>'allowed')::boolean and not (r->>'counted')::boolean, 'SOS must be allowed and uncounted';
  end loop;
  select messages_used into used from public.usage_counters
   where user_id = '00000000-0000-0000-0000-0000000000a1'
     and usage_day = public.usage_day_for('UTC');
  assert used = 3, format('messages_used %s, expected 3', used);
end $$;

-- 5) spend_coins as the user: insufficient → ok=false, balance unchanged; replay → spends once.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
do $$ declare r jsonb; b int; begin
  r := public.spend_coins('analysis', 'x', 'key-insufficient-1');   -- costs 30, balance 30 → ok
  assert (r->>'ok')::boolean, 'analysis spend should succeed: ' || r::text;
  r := public.spend_coins('msgs_20', 'coach', 'key-insufficient-2'); -- costs 10, balance 0
  assert not (r->>'ok')::boolean and r->>'reason' = 'insufficient', 'expected insufficient';
  select balance into b from public.coin_wallets where user_id = auth.uid();
  assert b = 0, format('balance %s, expected 0', b);
end $$;
reset role;

do $$ declare r jsonb; b int; begin
  perform public.credit_coins('00000000-0000-0000-0000-0000000000a1', 20, 'admin_adjust', 'test:topup');
end $$;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
do $$ declare r jsonb; b int; begin
  r := public.spend_coins('msgs_20', 'coach', 'key-replay-0001');
  r := public.spend_coins('msgs_20', 'coach', 'key-replay-0001');
  assert (r->>'replayed')::boolean, 'second call must be a replay';
  select balance into b from public.coin_wallets where user_id = auth.uid();
  assert b = 10, format('balance %s, expected 10 (spent once)', b);
end $$;

-- 6) Forged writes are denied for authenticated users.
do $$ begin
  begin
    update public.profiles set premium_expires_at = now() + interval '1 year' where id = auth.uid();
    assert false, 'premium_expires_at update should be denied';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set message_credits = 999 where id = auth.uid();
    assert false, 'message_credits update should be denied';
  exception when insufficient_privilege then null; end;
  begin
    perform public.credit_coins(auth.uid(), 1000, 'purchase', 'forged');
    assert false, 'credit_coins should be denied';
  exception when insufficient_privilege then null; end;
  begin
    perform public.consume_quota(auth.uid(), 'message', 'normal');
    assert false, 'consume_quota should be denied';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.coin_ledger (user_id, delta, kind, idempotency_key, balance_after)
      values (auth.uid(), 100, 'purchase', 'forged-ledger', 100);
    assert false, 'ledger insert should be denied';
  exception when insufficient_privilege then null; end;
end $$;

-- 7) Exit offer flag: true once, then false forever.
do $$ begin
  assert public.mark_exit_offer_shown() = true, 'first call wins';
  assert public.mark_exit_offer_shown() = false, 'second call must lose';
end $$;

-- 8) Conversations: origin fixed at creation; users cannot write messages directly.
do $$ declare c uuid; begin
  c := public.create_conversation('sos');
  assert (select origin from public.conversations where id = c) = 'sos', 'origin stored';
  begin
    insert into public.messages (conversation_id, user_id, role, content) values (c, auth.uid(), 'user', 'x');
    assert false, 'message insert should be denied';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

rollback;
