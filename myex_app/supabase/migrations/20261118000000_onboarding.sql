-- =============================================================================
-- Onboarding quiz answers (one row per user). Personalizes Plan ready, the
-- paywall and Mira. UNTESTED: written without the Supabase CLI.
-- Privacy: ex_name is optional and sensitive; it is only readable by its owner
-- (RLS) and never logged or sent to analytics.
-- =============================================================================
create table if not exists public.onboarding_answers (
  user_id            uuid primary key references auth.users on delete cascade,
  language           text not null default 'en' check (language in ('en', 'tr')),
  what_happened      text check (what_happened in ('they_ended','i_ended','mutual','complicated','on_off')),
  your_name          text check (length(your_name) <= 40),
  ex_name            text check (length(ex_name) <= 40),
  ended_on           date check (ended_on <= current_date + 1),
  relationship_length text check (relationship_length in ('lt6m','6to12m','1to3y','gt3y')),
  mood               smallint check (mood between 0 and 10),
  feelings           text[] not null default '{}'::text[],
  attachment_answers smallint[] not null default '{}'::smallint[],   -- 0..2 per question
  attachment_style   text check (attachment_style in ('secure','anxious','avoidant','fearful')),
  goals              text[] not null default '{}'::text[],
  completed_at       timestamptz,
  updated_at         timestamptz not null default now(),
  check (cardinality(feelings) <= 8),
  check (cardinality(goals) <= 3),
  check (cardinality(attachment_answers) <= 8)
);

alter table public.onboarding_answers enable row level security;

drop policy if exists onboarding_select_own on public.onboarding_answers;
create policy onboarding_select_own on public.onboarding_answers
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists onboarding_insert_own on public.onboarding_answers;
create policy onboarding_insert_own on public.onboarding_answers
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists onboarding_update_own on public.onboarding_answers;
create policy onboarding_update_own on public.onboarding_answers
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

revoke delete on public.onboarding_answers from anon, authenticated;

create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_onboarding_touch on public.onboarding_answers;
create trigger trg_onboarding_touch before update on public.onboarding_answers
  for each row execute function public.touch_updated_at();
