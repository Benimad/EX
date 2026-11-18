-- =============================================================================
-- MyEx core schema: profiles bootstrap, conversations/messages for Mira.
-- UNTESTED: written without the Supabase CLI. Run `supabase db reset` locally.
-- =============================================================================

-- ---------- PROFILES (base; monetization columns are added in the next migration)
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists no_contact_since date,          -- no-contact streak start
  add column if not exists remind_trial     boolean not null default true; -- paywall "remind me" (M5/M7)

-- Create a profile + wallet for every new auth user (incl. anonymous sign-ins).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- CONVERSATIONS (origin is fixed at creation, read server-side by mira-chat)
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  origin text not null default 'normal' check (origin in ('normal', 'sos')),
  created_at timestamptz not null default now()
);
create index if not exists conversations_user_idx on public.conversations (user_id, created_at desc);

alter table public.conversations enable row level security;
drop policy if exists conversations_select_own on public.conversations;
create policy conversations_select_own on public.conversations
  for select to authenticated using ((select auth.uid()) = user_id);
-- Writes only via create_conversation() / Edge Functions.
revoke insert, update, delete on public.conversations from anon, authenticated;

create or replace function public.create_conversation(p_origin text default 'normal')
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_id uuid;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_origin not in ('normal', 'sos') then raise exception 'bad origin'; end if;
  insert into public.conversations (user_id, origin) values (v_uid, p_origin) returning id into v_id;
  return v_id;
end $$;
revoke execute on function public.create_conversation(text) from public, anon;
grant execute on function public.create_conversation(text) to authenticated;

-- ---------- MESSAGES (written only by the mira-chat Edge Function, service role)
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.conversations on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (length(content) <= 8000),
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_idx on public.messages (conversation_id, created_at desc);
create index if not exists messages_user_idx on public.messages (user_id);

alter table public.messages enable row level security;
drop policy if exists messages_select_own on public.messages;
create policy messages_select_own on public.messages
  for select to authenticated using ((select auth.uid()) = user_id);
revoke insert, update, delete on public.messages from anon, authenticated;
