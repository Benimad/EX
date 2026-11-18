-- =============================================================================
-- Draft Jail: lock a text to the ex for 24 hours.
-- Free: 1 lock per usage day (09:00 local reset). Premium: unlimited.
-- SOS (HARD RULE 1): drafts written from SOS are never counted and never
-- blocked. Like SOS chats, the origin is client-declared; SOS is crisis-safe
-- by design, so "abusing" it only ever gives a user more help.
-- UNTESTED: written without the Supabase CLI.
-- =============================================================================

create table if not exists public.locked_drafts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  body         text not null check (length(btrim(body)) between 1 and 4000),
  origin       text not null default 'normal' check (origin in ('normal','sos')),
  created_at   timestamptz not null default now(),
  locked_until timestamptz not null,
  released_at  timestamptz
);
create index if not exists locked_drafts_user_idx on public.locked_drafts (user_id, created_at desc);

alter table public.locked_drafts enable row level security;
drop policy if exists drafts_read_own on public.locked_drafts;
create policy drafts_read_own on public.locked_drafts for select to authenticated
  using ((select auth.uid()) = user_id);
-- "Delete forever" is the user's right at any time, locked or not.
drop policy if exists drafts_delete_own on public.locked_drafts;
create policy drafts_delete_own on public.locked_drafts for delete to authenticated
  using ((select auth.uid()) = user_id);
revoke insert, update on public.locked_drafts from anon, authenticated;

alter table public.usage_counters
  add column if not exists sos_drafts int not null default 0;   -- telemetry only

-- consume_quota: same as the M2 version, plus the SOS bypass for drafts.
create or replace function public.consume_quota(p_uid uuid, p_kind text, p_origin text default 'normal')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  c_free_msgs constant int := 3;
  c_free_drafts constant int := 1;
  v_tz text; v_day date; v_row public.usage_counters%rowtype; v_credits int; v_resets timestamptz;
begin
  if p_kind not in ('message','draft') then raise exception 'bad kind'; end if;
  select coalesce(timezone,'UTC') into v_tz from public.profiles where id = p_uid;
  v_tz := coalesce(v_tz, 'UTC');
  v_day := public.usage_day_for(v_tz);
  v_resets := ((v_day + 1)::timestamp + interval '9 hours') at time zone v_tz;
  insert into public.usage_counters (user_id, usage_day) values (p_uid, v_day) on conflict do nothing;

  -- HARD RULE: SOS never counts and is never blocked (messages AND drafts).
  if p_origin = 'sos' then
    if p_kind = 'message' then
      update public.usage_counters set sos_messages = sos_messages + 1 where user_id = p_uid and usage_day = v_day;
    else
      update public.usage_counters set sos_drafts = sos_drafts + 1 where user_id = p_uid and usage_day = v_day;
    end if;
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

-- lock_draft: the only way to create a draft. Applies the free limit server-side.
create or replace function public.lock_draft(p_body text, p_origin text default 'normal')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); q jsonb; v_id uuid; v_until timestamptz := now() + interval '24 hours';
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_origin not in ('normal','sos') then raise exception 'bad origin'; end if;
  if p_body is null or length(btrim(p_body)) = 0 or length(p_body) > 4000 then raise exception 'bad body'; end if;
  q := public.consume_quota(v_uid, 'draft', p_origin);
  if not (q->>'allowed')::boolean then
    return jsonb_build_object('ok', false, 'reason', 'limit', 'resets_at', q->'resets_at');
  end if;
  insert into public.locked_drafts (user_id, body, origin, locked_until)
    values (v_uid, p_body, p_origin, v_until) returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'locked_until', v_until, 'via', q->>'via');
end $$;
revoke execute on function public.lock_draft(text, text) from public, anon;
grant execute on function public.lock_draft(text, text) to authenticated;

-- release_draft: only after the 24 hours have passed.
create or replace function public.release_draft(p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); d public.locked_drafts%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  select * into d from public.locked_drafts where id = p_id and user_id = v_uid for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'not_found'); end if;
  if d.locked_until > now() then
    return jsonb_build_object('ok', false, 'reason', 'locked', 'locked_until', d.locked_until);
  end if;
  update public.locked_drafts set released_at = coalesce(released_at, now()) where id = p_id;
  return jsonb_build_object('ok', true);
end $$;
revoke execute on function public.release_draft(uuid) from public, anon;
grant execute on function public.release_draft(uuid) to authenticated;

-- get_limits now also reports drafts honestly (drafts_left already existed).
