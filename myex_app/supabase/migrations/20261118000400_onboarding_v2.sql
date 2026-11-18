-- =============================================================================
-- Onboarding v2 (research R1, R9, R10): when it ended, contact level, hardest
-- times, check-in time; one onboarding "unsent message" saved to Draft Jail
-- that does NOT use the user's free daily draft.
-- UNTESTED: written without the Supabase CLI.
-- =============================================================================

alter table public.onboarding_answers
  add column if not exists ended_when    text check (ended_when in ('this_week','weeks','months','longer')),
  add column if not exists contact       text check (contact in ('none','sometimes','most_days','shared')),
  add column if not exists hardest_times text[] not null default '{}'::text[],
  add column if not exists checkin_hour  smallint check (checkin_hour between 0 and 23);

alter table public.onboarding_answers drop constraint if exists onboarding_answers_attachment_style_check;
alter table public.onboarding_answers add constraint onboarding_answers_attachment_style_check
  check (attachment_style in ('secure','anxious','avoidant','fearful'));

-- Drafts written during onboarding (R10).
alter table public.locked_drafts drop constraint if exists locked_drafts_origin_check;
alter table public.locked_drafts add constraint locked_drafts_origin_check
  check (origin in ('normal','sos','onboarding'));

create or replace function public.lock_draft(p_body text, p_origin text default 'normal')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); q jsonb; v_id uuid; v_until timestamptz := now() + interval '24 hours';
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_origin not in ('normal','sos','onboarding') then raise exception 'bad origin'; end if;
  if p_body is null or length(btrim(p_body)) = 0 or length(p_body) > 4000 then raise exception 'bad body'; end if;
  if p_origin = 'onboarding' then
    -- One free onboarding draft per user, never counted against the daily limit.
    if exists (select 1 from public.locked_drafts where user_id = v_uid and origin = 'onboarding') then
      return jsonb_build_object('ok', false, 'reason', 'already_saved');
    end if;
  else
    q := public.consume_quota(v_uid, 'draft', p_origin);
    if not (q->>'allowed')::boolean then
      return jsonb_build_object('ok', false, 'reason', 'limit', 'resets_at', q->'resets_at');
    end if;
  end if;
  insert into public.locked_drafts (user_id, body, origin, locked_until)
    values (v_uid, p_body, p_origin, v_until) returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'locked_until', v_until);
end $$;
revoke execute on function public.lock_draft(text, text) from public, anon;
grant execute on function public.lock_draft(text, text) to authenticated;
