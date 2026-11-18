-- =============================================================================
-- Plan gating + Draft Jail SQL tests (DO blocks + ASSERT, rolled back).
-- UNTESTED. Run after `supabase db reset`:
--   psql "<local db url>" -f supabase/tests/plan_drafts_test.sql
-- =============================================================================
begin;

insert into auth.users (id, instance_id, aud, role, email)
values ('00000000-0000-0000-0000-0000000000c3', '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated', 'c@test.local');

create or replace function pg_temp.as_c() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', '00000000-0000-0000-0000-0000000000c3', 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

-- ---------------- Plan ----------------
select pg_temp.as_c();
do $$ declare r jsonb; begin
  -- Day 1 open, Day 2 waiting, Day 4 locked (free).
  assert public.plan_day_status(auth.uid(), 1) = 'open', 'day 1 open';
  assert public.plan_day_status(auth.uid(), 2) = 'waiting', 'day 2 waits for day 1';
  assert public.plan_day_status(auth.uid(), 4) = 'locked', 'day 4 locked for free users';

  -- Locked content never reaches the client.
  r := public.get_plan_day(4);
  assert r->>'prompt' is null, 'locked prompt must be null';
  assert (select count(*) from public.plan_day_content where day = 4) = 0, 'RLS hides day 4 content';
  assert (select count(*) from public.plan_day_content where day = 1) = 1, 'day 1 content visible';

  -- Complete day 1; day 2 still waits (same usage day).
  r := public.complete_plan_day(1, array['a','b','c']);
  assert (r->>'ok')::boolean, 'day 1 completes';
  assert public.plan_day_status(auth.uid(), 2) = 'waiting', 'one new day per day';
  r := public.complete_plan_day(2, array['a','b','c']);
  assert not (r->>'ok')::boolean and r->>'reason' = 'waiting', 'day 2 rejected today';

  -- Bad input is rejected.
  begin
    perform public.complete_plan_day(1, array['a','b']);
    assert false, 'two entries must fail';
  exception when raise_exception then null; end;

  -- Users can't write progress directly.
  begin
    insert into public.user_plan_progress (user_id, day, entries) values (auth.uid(), 3, array['a','b','c']);
    assert false, 'direct insert must be denied';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Simulate "tomorrow": move day 1's completion back one day → day 2 opens.
update public.user_plan_progress set completed_at = completed_at - interval '1 day'
 where user_id = '00000000-0000-0000-0000-0000000000c3' and day = 1;
select pg_temp.as_c();
do $$ begin
  assert public.plan_day_status(auth.uid(), 2) = 'open', 'day 2 opens the next usage day';
end $$;
reset role;

-- Coin unlock opens exactly one locked day.
insert into public.content_unlocks (user_id, kind, ref) values ('00000000-0000-0000-0000-0000000000c3', 'plan_day', '5');
select pg_temp.as_c();
do $$ begin
  assert public.can_access_plan_day(auth.uid(), 5), 'day 5 unlocked with coins';
  assert not public.can_access_plan_day(auth.uid(), 6), 'day 6 still locked';
end $$;

-- ---------------- Draft Jail ----------------
do $$ declare r jsonb; i int; begin
  r := public.lock_draft('first', 'normal');
  assert (r->>'ok')::boolean, 'first free draft locks';
  r := public.lock_draft('second', 'normal');
  assert not (r->>'ok')::boolean and r->>'reason' = 'limit', 'second free draft hits the limit';
  -- SOS never limits, even after the free draft is used.
  for i in 1..10 loop
    r := public.lock_draft('from sos ' || i, 'sos');
    assert (r->>'ok')::boolean, 'SOS drafts are never limited';
  end loop;
  -- Can't release before 24h.
  r := public.release_draft((select id from public.locked_drafts where body = 'first'));
  assert not (r->>'ok')::boolean and r->>'reason' = 'locked', 'still locked';
  -- Users can't insert or extend drafts directly.
  begin
    insert into public.locked_drafts (user_id, body, locked_until) values (auth.uid(), 'x', now());
    assert false, 'direct insert denied';
  exception when insufficient_privilege then null; end;
  -- Delete forever works for own drafts.
  delete from public.locked_drafts where body = 'first';
  assert not exists (select 1 from public.locked_drafts where body = 'first'), 'deleted';
end $$;
reset role;

do $$ declare v int; begin
  select drafts_used into v from public.usage_counters
   where user_id = '00000000-0000-0000-0000-0000000000c3' and usage_day = public.usage_day_for('UTC');
  assert v = 1, format('only the normal draft counted (got %s)', v);
end $$;

rollback;
