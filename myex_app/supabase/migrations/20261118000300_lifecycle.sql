-- =============================================================================
-- M7 lifecycle: value recap for the trial reminder + Trial status, win-back
-- eligibility (7–14 days after expiry, once), local-reminder bookkeeping.
-- Server push backup (lifecycle-push + notification_log) is a later step.
-- UNTESTED: written without the Supabase CLI.
-- =============================================================================

alter table public.profiles
  add column if not exists trial_reminder_local_at timestamptz;
grant update (trial_reminder_local_at) on public.profiles to authenticated;

-- Real usage numbers only (talks, texts not sent, plan days done, streak).
create or replace function public.get_value_recap() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_since timestamptz; v_nc date;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  select coalesce(trial_started_at, now() - interval '30 days'), no_contact_since
    into v_since, v_nc from public.profiles where id = v_uid;
  v_since := coalesce(v_since, now() - interval '30 days');
  return jsonb_build_object(
    'talks', (select count(*) from public.messages m
               where m.user_id = v_uid and m.role = 'user' and m.created_at >= v_since),
    'drafts_not_sent', (select count(*) from public.locked_drafts d
               where d.user_id = v_uid and d.created_at >= v_since),
    'days_done', (select count(*) from public.user_plan_progress p where p.user_id = v_uid),
    'streak_days', case when v_nc is null then 0 else greatest(current_date - v_nc, 0) end);
end $$;
revoke execute on function public.get_value_recap() from public, anon;
grant execute on function public.get_value_recap() to authenticated;

-- Win-back: lapsed 7–14 days ago, not premium now, never shown before.
create or replace function public.winback_eligible() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select p.premium_lapsed_at between now() - interval '14 days' and now() - interval '7 days'
       and p.winback_shown_at is null
       and not public.is_premium(p.id)
    from public.profiles p where p.id = auth.uid()), false);
$$;
revoke execute on function public.winback_eligible() from public, anon;
grant execute on function public.winback_eligible() to authenticated;

-- True only for the call that wins the right to show win-back (once, ever).
create or replace function public.mark_winback_shown() returns boolean
language plpgsql security definer set search_path = '' as $$
declare v_updated int;
begin
  update public.profiles set winback_shown_at = now()
   where id = auth.uid() and winback_shown_at is null;
  get diagnostics v_updated = row_count;
  return v_updated = 1;
end $$;
revoke execute on function public.mark_winback_shown() from public, anon;
grant execute on function public.mark_winback_shown() to authenticated;
