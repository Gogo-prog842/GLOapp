-- ============================================================
-- GLO: konta sędziów + przypisywanie sędziego do meczu
-- Uruchom w Supabase SQL Editor jako właściciel projektu.
-- ============================================================

-- 1) Lista kont sędziów rozpoznawanych po emailu logowania.
create table if not exists public.referee_accounts (
    id bigserial primary key,
    email text not null unique,
    name text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint referee_accounts_email_lower check (email = lower(trim(email)))
);

create index if not exists idx_referee_accounts_email on public.referee_accounts (lower(email));

-- 2) Email sędziego przypisany do konkretnego meczu.
alter table public.matches
    add column if not exists referee_email text;

create index if not exists idx_matches_referee_email on public.matches (lower(referee_email));

-- 3) RLS dla kont sędziów.
alter table public.referee_accounts enable row level security;

drop policy if exists "referee_accounts_select_own_or_admin" on public.referee_accounts;
create policy "referee_accounts_select_own_or_admin"
on public.referee_accounts
for select
to authenticated
using (
    lower(email) = lower(coalesce(auth.email(), ''))
    or exists (
        select 1 from public.admins a
        where lower(a.email) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "referee_accounts_admin_insert" on public.referee_accounts;
create policy "referee_accounts_admin_insert"
on public.referee_accounts
for insert
to authenticated
with check (
    exists (
        select 1 from public.admins a
        where lower(a.email) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "referee_accounts_admin_update" on public.referee_accounts;
create policy "referee_accounts_admin_update"
on public.referee_accounts
for update
to authenticated
using (
    exists (
        select 1 from public.admins a
        where lower(a.email) = lower(coalesce(auth.email(), ''))
    )
)
with check (
    exists (
        select 1 from public.admins a
        where lower(a.email) = lower(coalesce(auth.email(), ''))
    )
);

drop policy if exists "referee_accounts_admin_delete" on public.referee_accounts;
create policy "referee_accounts_admin_delete"
on public.referee_accounts
for delete
to authenticated
using (
    exists (
        select 1 from public.admins a
        where lower(a.email) = lower(coalesce(auth.email(), ''))
    )
);

-- 4) Sędzia może widzieć i aktualizować tylko mecze przypisane do swojego emaila.
-- Jeżeli masz już własne polityki, te są dodatkowe i nie usuwają starych.
alter table public.matches enable row level security;

drop policy if exists "matches_referee_select_assigned" on public.matches;
create policy "matches_referee_select_assigned"
on public.matches
for select
to authenticated
using (
    lower(coalesce(referee_email, '')) = lower(coalesce(auth.email(), ''))
);

drop policy if exists "matches_referee_update_assigned" on public.matches;
create policy "matches_referee_update_assigned"
on public.matches
for update
to authenticated
using (
    lower(coalesce(referee_email, '')) = lower(coalesce(auth.email(), ''))
)
with check (
    lower(coalesce(referee_email, '')) = lower(coalesce(auth.email(), ''))
);

-- 5) Protokół meczowy: gole/asysty, składy, kartki i obrony bramkarzy.
alter table public.match_goals enable row level security;

drop policy if exists "match_goals_referee_all_assigned" on public.match_goals;
create policy "match_goals_referee_all_assigned"
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

alter table public.match_lineups enable row level security;

drop policy if exists "match_lineups_referee_all_assigned" on public.match_lineups;
create policy "match_lineups_referee_all_assigned"
on public.match_lineups
for all
to authenticated
using (
    exists (
        select 1 from public.matches m
        where m.id = match_lineups.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
)
with check (
    exists (
        select 1 from public.matches m
        where m.id = match_lineups.match_id
          and lower(coalesce(m.referee_email, '')) = lower(coalesce(auth.email(), ''))
    )
);

alter table public.match_cards enable row level security;

drop policy if exists "match_cards_referee_all_assigned" on public.match_cards;
create policy "match_cards_referee_all_assigned"
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

-- match_goalkeeper_stats istnieje, jeśli uruchomiony był plik supabase-goalkeeper-stats.sql.
do $$
begin
    if to_regclass('public.match_goalkeeper_stats') is not null then
        execute 'alter table public.match_goalkeeper_stats enable row level security';
        execute 'drop policy if exists "match_goalkeeper_stats_referee_all_assigned" on public.match_goalkeeper_stats';
        execute $pol$
            create policy "match_goalkeeper_stats_referee_all_assigned"
            on public.match_goalkeeper_stats
            for all
            to authenticated
            using (
                exists (
                    select 1 from public.matches m
                    where m.id = match_goalkeeper_stats.match_id
                      and lower(coalesce(m.referee_email, '''')) = lower(coalesce(auth.email(), ''''))
                )
            )
            with check (
                exists (
                    select 1 from public.matches m
                    where m.id = match_goalkeeper_stats.match_id
                      and lower(coalesce(m.referee_email, '''')) = lower(coalesce(auth.email(), ''''))
                )
            )
        $pol$;
    end if;
end $$;

-- 6) Przydatny trigger na updated_at.
create or replace function public.set_referee_accounts_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    new.email = lower(trim(new.email));
    return new;
end $$;

drop trigger if exists trg_referee_accounts_updated_at on public.referee_accounts;
create trigger trg_referee_accounts_updated_at
before insert or update on public.referee_accounts
for each row execute function public.set_referee_accounts_updated_at();
