-- =============================================================================
-- 30-day plan: catalog (teasers readable by all, content gated), per-user
-- progress, and the server-side gate (M6 §3 + founder spec):
--   * Free covers Days 1–3. Days 4–30 need Premium or a coin unlock
--     (spend_coins('plan_day', '<n>') → content_unlocks).
--   * One new day opens per day: Day N opens once Day N-1 is done AND the
--     local usage day (09:00 reset, profiles.timezone) has advanced since then.
-- The client mirrors this logic for display only; these functions decide.
-- UNTESTED: written without the Supabase CLI.
-- =============================================================================

create table if not exists public.plan_days (           -- teasers: always visible
  day        smallint primary key check (day between 1 and 30),
  stage      text not null check (stage in ('week1','week2','week3','rebuild')),
  minutes    smallint not null check (minutes between 1 and 30),
  title_en   text not null,
  title_tr   text not null,
  promise_en text not null,
  promise_tr text not null
);

create table if not exists public.plan_day_content (     -- gated by RLS
  day       smallint primary key references public.plan_days on delete cascade,
  prompt_en text not null,
  prompt_tr text not null
);

create table if not exists public.user_plan_progress (
  user_id      uuid not null references auth.users on delete cascade,
  day          smallint not null references public.plan_days,
  completed_at timestamptz not null default now(),
  entries      text[] not null check (cardinality(entries) = 3),
  primary key (user_id, day)
);
create index if not exists user_plan_progress_user_idx on public.user_plan_progress (user_id, completed_at);

-- ---------- Access + time gate ----------
create or replace function public.can_access_plan_day(p_uid uuid, p_day int) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_day between 1 and 3
      or public.is_premium(p_uid)
      or exists (select 1 from public.content_unlocks u
                 where u.user_id = p_uid and u.kind = 'plan_day' and u.ref = p_day::text);
$$;
revoke execute on function public.can_access_plan_day(uuid, int) from public, anon;
grant execute on function public.can_access_plan_day(uuid, int) to authenticated, service_role;

-- 'done' | 'open' | 'waiting' (time gate / previous day not done) | 'locked' (needs Premium/coins)
create or replace function public.plan_day_status(p_uid uuid, p_day int) returns text
language plpgsql stable security definer set search_path = '' as $$
declare v_tz text; v_prev timestamptz;
begin
  if exists (select 1 from public.user_plan_progress where user_id = p_uid and day = p_day) then
    return 'done';
  end if;
  if not public.can_access_plan_day(p_uid, p_day) then return 'locked'; end if;
  if p_day = 1 then return 'open'; end if;
  select completed_at into v_prev from public.user_plan_progress where user_id = p_uid and day = p_day - 1;
  if v_prev is null then return 'waiting'; end if;
  select coalesce(timezone, 'UTC') into v_tz from public.profiles where id = p_uid;
  if public.usage_day_for(v_tz, v_prev) < public.usage_day_for(v_tz) then return 'open'; end if;
  return 'waiting';
end $$;
revoke execute on function public.plan_day_status(uuid, int) from public, anon;
grant execute on function public.plan_day_status(uuid, int) to authenticated, service_role;

-- ---------- RLS ----------
alter table public.plan_days          enable row level security;
alter table public.plan_day_content   enable row level security;
alter table public.user_plan_progress enable row level security;

drop policy if exists plan_days_read on public.plan_days;
create policy plan_days_read on public.plan_days for select to authenticated using (true);

-- Locked day content never reaches a client that can't access it.
drop policy if exists plan_content_read on public.plan_day_content;
create policy plan_content_read on public.plan_day_content for select to authenticated
  using (public.can_access_plan_day((select auth.uid()), day));

drop policy if exists progress_read_own on public.user_plan_progress;
create policy progress_read_own on public.user_plan_progress for select to authenticated
  using ((select auth.uid()) = user_id);
revoke insert, update, delete on public.user_plan_progress from anon, authenticated;
revoke insert, update, delete on public.plan_days, public.plan_day_content from anon, authenticated;

-- ---------- RPCs ----------
create or replace function public.get_plan_day(p_day int) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_lang text; v_status text; t public.plan_days%rowtype;
        c public.plan_day_content%rowtype; v_entries text[];
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  select * into t from public.plan_days where day = p_day;
  if not found then raise exception 'bad day'; end if;
  select coalesce(locale, 'en') into v_lang from public.profiles where id = v_uid;
  v_status := public.plan_day_status(v_uid, p_day);
  if v_status <> 'locked' then
    select * into c from public.plan_day_content where day = p_day;
  end if;
  select entries into v_entries from public.user_plan_progress where user_id = v_uid and day = p_day;
  return jsonb_build_object(
    'day', t.day, 'minutes', t.minutes, 'status', v_status,
    'title', case when v_lang = 'tr' then t.title_tr else t.title_en end,
    'promise', case when v_lang = 'tr' then t.promise_tr else t.promise_en end,
    'prompt', case when v_status = 'locked' then null
                   when v_lang = 'tr' then c.prompt_tr else c.prompt_en end,
    'entries', v_entries);
end $$;
revoke execute on function public.get_plan_day(int) from public, anon;
grant execute on function public.get_plan_day(int) to authenticated;

create or replace function public.complete_plan_day(p_day int, p_entries text[]) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_status text; v_tz text; v_day date; e text;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_entries is null or cardinality(p_entries) <> 3 then raise exception 'need 3 entries'; end if;
  foreach e in array p_entries loop
    if e is null or length(btrim(e)) = 0 or length(e) > 500 then raise exception 'bad entry'; end if;
  end loop;
  -- Serialize per user so double taps can't race the gate.
  perform 1 from public.profiles where id = v_uid for update;
  v_status := public.plan_day_status(v_uid, p_day);
  if v_status = 'done' then return jsonb_build_object('ok', true, 'already_done', true); end if;
  if v_status <> 'open' then return jsonb_build_object('ok', false, 'reason', v_status); end if;
  insert into public.user_plan_progress (user_id, day, entries) values (v_uid, p_day, p_entries);
  select coalesce(timezone, 'UTC') into v_tz from public.profiles where id = v_uid;
  v_day := public.usage_day_for(v_tz);
  return jsonb_build_object('ok', true, 'day', p_day,
    'next_opens_at', ((v_day + 1)::timestamp + interval '9 hours') at time zone v_tz);
end $$;
revoke execute on function public.complete_plan_day(int, text[]) from public, anon;
grant execute on function public.complete_plan_day(int, text[]) to authenticated;

-- ---------- Seed (EN + TR). Have a native speaker proofread TR. ----------
insert into public.plan_days (day, stage, minutes, title_en, title_tr, promise_en, promise_tr) values
 (1,'week1',5,'Mute, don’t stalk','Sessize al, takip etme','Fewer reminders, fewer spirals.','Daha az hatırlatma, daha az kısır döngü.'),
 (2,'week1',5,'Your non-negotiables','Vazgeçilmezlerin','Remember what you need.','Neye ihtiyacın olduğunu hatırla.'),
 (3,'week1',5,'Three things you don’t miss','Özlemediğin üç şey','Balance the highlight reel.','Güzel anıları dengele.'),
 (4,'week1',5,'Put the photos away','Fotoğrafları kaldır','Let go of the photos, without losing the memories.','Anıları kaybetmeden fotoğraflardan ayrıl.'),
 (5,'week1',6,'The unsent letter','Gönderilmeyen mektup','Say it, without sending it.','Söyle ama gönderme.'),
 (6,'week1',5,'Your new Sunday','Yeni pazarın','Fill the empty hours.','Boş saatleri doldur.'),
 (7,'week1',6,'Rewrite the story','Hikâyeyi yeniden yaz','You are more than how it ended.','Bitiş şeklinden fazlasısın.'),
 (8,'week2',5,'Meet your anxious side','Kaygılı tarafınla tanış','Name the urge, then let it pass.','Dürtüyü adlandır, sonra geçmesine izin ver.'),
 (9,'week2',5,'Your support circle','Destek çemberin','You don’t have to do this alone.','Bunu tek başına yapmak zorunda değilsin.'),
 (10,'week2',5,'Sleep reset','Uyku düzeni','Rest is part of healing.','Dinlenmek iyileşmenin parçası.'),
 (11,'week2',5,'What you gave','Neler verdin','See your own effort.','Kendi emeğini gör.'),
 (12,'week2',6,'Red flags, gently','Kırmızı bayraklar, nazikçe','Notice without blame.','Suçlamadan fark et.'),
 (13,'week2',5,'Body check','Beden kontrolü','Feelings live in the body too.','Duygular bedende de yaşar.'),
 (14,'week2',5,'Two weeks in','İki hafta oldu','Look how far you’ve come.','Ne kadar yol aldığına bak.'),
 (15,'week3',5,'Your values','Değerlerin','Steer by what matters to you.','Senin için önemli olanla yön bul.'),
 (16,'week3',5,'Small brave things','Küçük cesaretler','Confidence comes from doing.','Güven yaparak gelir.'),
 (17,'week3',5,'Friendship check','Arkadaşlıklar','Reconnect with people who lift you.','Seni iyi hissettiren insanlarla yeniden bağ kur.'),
 (18,'week3',5,'Old hobby, new you','Eski hobi, yeni sen','Return to what you loved before.','Daha önce sevdiğin şeylere dön.'),
 (19,'week3',6,'Your triggers map','Tetikleyiciler haritası','Know your hard moments.','Zor anlarını tanı.'),
 (20,'week3',6,'Forgiving yourself','Kendini affetmek','You did the best you could.','Elinden geleni yaptın.'),
 (21,'week3',5,'Three weeks','Üç hafta','Habits are forming.','Alışkanlıklar oluşuyor.'),
 (22,'rebuild',5,'Your space','Alanın','Make your home feel like yours.','Evini kendine ait hissettir.'),
 (23,'rebuild',5,'Your mornings','Sabahların','Structure that holds you.','Seni taşıyan bir düzen.'),
 (24,'rebuild',5,'Move for you','Kendin için hareket et','Move for how it feels.','Nasıl hissettirdiği için hareket et.'),
 (25,'rebuild',6,'Your next six months','Önümüzdeki altı ay','A future that is yours.','Sana ait bir gelecek.'),
 (26,'rebuild',6,'Your boundaries','Sınırların','Kind and clear.','Nazik ve net.'),
 (27,'rebuild',4,'What’s good today','Bugün iyi olan','Notice what’s working.','İşe yarayanı fark et.'),
 (28,'rebuild',5,'Who you’re becoming','Dönüştüğün kişi','Tell your story your way.','Hikâyeni kendi bakış açınla anlat.'),
 (29,'rebuild',6,'A letter to future you','Gelecekteki sana mektup','Encourage the next you.','Gelecekteki sana cesaret ver.'),
 (30,'rebuild',6,'Day 30','30. gün','You stayed with yourself.','Kendinin yanında kaldın.')
on conflict (day) do update set stage = excluded.stage, minutes = excluded.minutes,
  title_en = excluded.title_en, title_tr = excluded.title_tr,
  promise_en = excluded.promise_en, promise_tr = excluded.promise_tr;

insert into public.plan_day_content (day, prompt_en, prompt_tr) values
 (1,'Write three places where you usually check on them, and how you’ll mute each one.','Onu genelde kontrol ettiğin üç yeri ve her birini nasıl sessize alacağını yaz.'),
 (2,'Write three things you need from a partner that you won’t give up again.','Bir partnerden ihtiyaç duyduğun ve bir daha vazgeçmeyeceğin üç şeyi yaz.'),
 (3,'Write three things about the relationship that you don’t miss.','İlişkide özlemediğin üç şeyi yaz.'),
 (4,'Move the photos out of sight. Then write three memories you want to keep in words instead.','Fotoğrafları gözden uzaklaştır. Sonra onların yerine kelimelerle saklamak istediğin üç anıyı yaz.'),
 (5,'Write three things you wish you could tell them. This stays here.','Ona söylemek istediğin üç şeyi yaz. Bu burada kalır.'),
 (6,'Write three things you’ll do this weekend that are just for you.','Bu hafta sonu sadece kendin için yapacağın üç şeyi yaz.'),
 (7,'Write three true sentences about the breakup that don’t blame you.','Ayrılık hakkında seni suçlamayan üç doğru cümle yaz.'),
 (8,'Write three moments when you wanted to reach out, and what you did instead.','Ona ulaşmak istediğin üç anı ve onun yerine ne yaptığını yaz.'),
 (9,'Write three people you could call on a hard night.','Zor bir gecede arayabileceğin üç kişiyi yaz.'),
 (10,'Write three changes to your evening that would help you sleep.','Uyumana yardımcı olacak üç akşam değişikliği yaz.'),
 (11,'Write three things you gave in the relationship that you’re proud of.','İlişkide verdiğin ve gurur duyduğun üç şeyi yaz.'),
 (12,'Write three signs you would notice earlier next time.','Bir dahaki sefere daha erken fark edeceğin üç işareti yaz.'),
 (13,'Write three ways your body felt this week, and one kind thing for each.','Bu hafta bedeninin hissettiği üç şeyi ve her biri için nazik bir şeyi yaz.'),
 (14,'Write three things that are easier now than on Day 1.','Şimdi 1. güne göre daha kolay olan üç şeyi yaz.'),
 (15,'Write three values you want your next chapter to be built on.','Yeni döneminin üzerine kurulmasını istediğin üç değeri yaz.'),
 (16,'Write three small brave things you could do this week.','Bu hafta yapabileceğin üç küçük cesur şeyi yaz.'),
 (17,'Write three friends you want to see more, and one plan with each.','Daha sık görmek istediğin üç arkadaşı ve her biriyle bir planı yaz.'),
 (18,'Write three things you enjoyed before the relationship.','İlişkiden önce keyif aldığın üç şeyi yaz.'),
 (19,'Write three triggers (a song, a place, a time of day) and what you’ll do when they come.','Üç tetikleyiciyi (bir şarkı, bir yer, günün bir saati) ve geldiklerinde ne yapacağını yaz.'),
 (20,'Write three things you forgive yourself for.','Kendini affettiğin üç şeyi yaz.'),
 (21,'Write three new habits that are starting to stick.','Yerleşmeye başlayan üç yeni alışkanlığını yaz.'),
 (22,'Write three changes that would make your home feel like yours.','Evini sana ait hissettirecek üç değişikliği yaz.'),
 (23,'Write three parts of a morning routine you’d like to keep.','Sürdürmek istediğin bir sabah rutininin üç parçasını yaz.'),
 (24,'Write three ways you’ll move your body this week.','Bu hafta bedenini hareket ettireceğin üç yolu yaz.'),
 (25,'Write three things you want in the next six months.','Önümüzdeki altı ayda istediğin üç şeyi yaz.'),
 (26,'Write three boundaries you’ll keep if they reach out.','Sana ulaşırsa koruyacağın üç sınırı yaz.'),
 (27,'Write three things that are good today, however small.','Ne kadar küçük olursa olsun, bugün iyi olan üç şeyi yaz.'),
 (28,'Write three sentences about who you’re becoming.','Dönüştüğün kişi hakkında üç cümle yaz.'),
 (29,'Write three things you want future you to remember.','Gelecekteki senin hatırlamasını istediğin üç şeyi yaz.'),
 (30,'Write three things you’re proud of from these 30 days.','Bu 30 günden gurur duyduğun üç şeyi yaz.')
on conflict (day) do update set prompt_en = excluded.prompt_en, prompt_tr = excluded.prompt_tr;
