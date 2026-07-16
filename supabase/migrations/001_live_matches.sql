-- ============================================================
-- GLO: obsługa meczów LIVE + zegar meczu
-- Uruchom w Supabase SQL Editor jako właściciel projektu.
-- Po tym frontend może prowadzić mecz live, liczyć czas 2x30 min,
-- przerwę 10 min, doliczony czas i dopisywać zdarzenia z automatyczną minutą.
-- ============================================================

-- 1) Pola live w tabeli matches.
alter table public.matches
    add column if not exists live_started_at timestamptz,
    add column if not exists live_finished_at timestamptz,
    add column if not exists live_last_event_at timestamptz,
    add column if not exists live_period text default 'not_started',
    add column if not exists live_clock_started_at timestamptz,
    add column if not exists live_elapsed_seconds integer default 0,
    add column if not exists live_break_started_at timestamptz,
    add column if not exists live_break_seconds integer default 600,
    add column if not exists live_added_first_seconds integer default 0,
    add column if not exists live_added_second_seconds integer default 0;

-- live_period:
-- not_started  = przed startem
-- first_half   = I połowa, zegar od 00:00 do 30:00 i dalej 30+X
-- half_time    = przerwa, domyślnie 10 minut
-- second_half  = II połowa, zegar od 30:00 do 60:00 i dalej 60+X
-- finished     = zakończony

do $$
declare
    c record;
begin
    for c in
        select conname
        from pg_constraint
        where conrelid = 'public.matches'::regclass
          and contype = 'c'
          and pg_get_constraintdef(oid) ilike '%status%'
    loop
        execute format('alter table public.matches drop constraint if exists %I', c.conname);
    end loop;
end $$;

alter table public.matches
    add constraint matches_status_check
    check (status in ('scheduled', 'live', 'completed', 'cancelled', 'canceled'));

do $$
declare
    c record;
begin
    for c in
        select conname
        from pg_constraint
        where conrelid = 'public.matches'::regclass
          and contype = 'c'
          and pg_get_constraintdef(oid) ilike '%live_period%'
    loop
        execute format('alter table public.matches drop constraint if exists %I', c.conname);
    end loop;
end $$;

alter table public.matches
    add constraint matches_live_period_check
    check (live_period is null or live_period in ('not_started', 'first_half', 'half_time', 'second_half', 'finished'));

create index if not exists idx_matches_status on public.matches(status);
create index if not exists idx_matches_live on public.matches(status, date) where status = 'live';
create index if not exists idx_matches_live_period on public.matches(live_period) where status = 'live';

-- 2) Pola minut dla zdarzeń. minute zostaje integerem kompatybilnym ze starym kodem.
-- extra_minute pozwala wyświetlać np. 30+2 albo 60+1.
alter table public.match_goals
    add column if not exists live_period text,
    add column if not exists extra_minute integer,
    add column if not exists created_at timestamptz default now();

alter table public.match_cards
    add column if not exists live_period text,
    add column if not exists extra_minute integer,
    add column if not exists created_at timestamptz default now();

-- 3) Typy goli.
do $$
declare
    c record;
begin
    for c in
        select conname
        from pg_constraint
        where conrelid = 'public.match_goals'::regclass
          and contype = 'c'
          and pg_get_constraintdef(oid) ilike '%type%'
    loop
        execute format('alter table public.match_goals drop constraint if exists %I', c.conname);
    end loop;
end $$;

alter table public.match_goals
    add constraint match_goals_type_check
    check (type is null or type in ('normal', 'penalty', 'own_goal', 'assist_only'));

create index if not exists idx_match_goals_match_minute on public.match_goals(match_id, minute, extra_minute, id);
create index if not exists idx_match_cards_match_minute on public.match_cards(match_id, minute, extra_minute, id);

-- 4) Trigger audytowy: daty startu/końca i ostatnia zmiana live.
create or replace function public.set_match_live_timestamps()
returns trigger
language plpgsql
as $$
begin
    if new.status = 'live' and coalesce(old.status, '') <> 'live' then
        new.live_started_at = coalesce(new.live_started_at, now());
        new.live_finished_at = null;
        new.live_period = coalesce(new.live_period, 'first_half');
    end if;

    if new.status = 'completed' and coalesce(old.status, '') = 'live' then
        new.live_finished_at = coalesce(new.live_finished_at, now());
        new.live_period = 'finished';
        new.live_clock_started_at = null;
        new.live_break_started_at = null;
    end if;

    if new.status = 'live' then
        new.live_last_event_at = now();
    end if;

    return new;
end $$;

drop trigger if exists trg_matches_live_timestamps on public.matches;
create trigger trg_matches_live_timestamps
before update on public.matches
for each row execute function public.set_match_live_timestamps();

-- 5) RLS: sędzia przypisany do meczu może go aktualizować i dopisywać zdarzenia.
alter table public.matches enable row level security;
alter table public.match_goals enable row level security;
alter table public.match_cards enable row level security;

drop policy if exists "matches_referee_update_assigned_live" on public.matches;
create policy "matches_referee_update_assigned_live"
on public.matches
for update
to authenticated
using (lower(coalesce(referee_email, '')) = lower(coalesce(auth.email(), '')))
with check (lower(coalesce(referee_email, '')) = lower(coalesce(auth.email(), '')));

drop policy if exists "match_goals_referee_all_assigned_live" on public.match_goals;
create policy "match_goals_referee_all_assigned_live"
on public.match_goals
for all
to authenticated
using (
    exists (
        select 1 from public.matches m
        where m.id = match_goals.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
)
with check (
    exists (
        select 1 from public.matches m
        where m.id = match_goals.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "match_cards_referee_all_assigned_live" on public.match_cards;
create policy "match_cards_referee_all_assigned_live"
on public.match_cards
for all
to authenticated
using (
    exists (
        select 1 from public.matches m
        where m.id = match_cards.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
)
with check (
    exists (
        select 1 from public.matches m
        where m.id = match_cards.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
);
