-- GLO: statystyki bramkarzy w meczu
-- Uruchom ten plik w Supabase -> SQL Editor przed użyciem pola 🧤 w panelu admina.

create table if not exists public.match_goalkeeper_stats (
    id bigserial primary key,
    match_id bigint not null references public.matches(id) on delete cascade,
    player_id bigint not null references public.players(id) on delete cascade,
    team_id bigint references public.teams(id) on delete set null,
    saves integer not null default 0 check (saves >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint match_goalkeeper_stats_match_player_key unique (match_id, player_id)
);

create index if not exists idx_match_goalkeeper_stats_match_id on public.match_goalkeeper_stats(match_id);
create index if not exists idx_match_goalkeeper_stats_player_id on public.match_goalkeeper_stats(player_id);
create index if not exists idx_match_goalkeeper_stats_team_id on public.match_goalkeeper_stats(team_id);

create or replace function public.set_match_goalkeeper_stats_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_match_goalkeeper_stats_updated_at on public.match_goalkeeper_stats;
create trigger trg_match_goalkeeper_stats_updated_at
before update on public.match_goalkeeper_stats
for each row execute function public.set_match_goalkeeper_stats_updated_at();

grant select on public.match_goalkeeper_stats to anon, authenticated;
grant insert, update, delete on public.match_goalkeeper_stats to authenticated;
grant usage, select on sequence public.match_goalkeeper_stats_id_seq to authenticated;

alter table public.match_goalkeeper_stats enable row level security;

drop policy if exists "match_goalkeeper_stats_select" on public.match_goalkeeper_stats;
create policy "match_goalkeeper_stats_select"
on public.match_goalkeeper_stats
for select
using (true);

drop policy if exists "match_goalkeeper_stats_insert" on public.match_goalkeeper_stats;
create policy "match_goalkeeper_stats_insert"
on public.match_goalkeeper_stats
for insert
to authenticated
with check (true);

drop policy if exists "match_goalkeeper_stats_update" on public.match_goalkeeper_stats;
create policy "match_goalkeeper_stats_update"
on public.match_goalkeeper_stats
for update
to authenticated
using (true)
with check (true);

drop policy if exists "match_goalkeeper_stats_delete" on public.match_goalkeeper_stats;
create policy "match_goalkeeper_stats_delete"
on public.match_goalkeeper_stats
for delete
to authenticated
using (true);

-- Opcjonalna część tej aktualizacji: ukrywanie zawodników bez kasowania historii.
alter table public.players
    add column if not exists is_hidden boolean not null default false;

create index if not exists idx_players_is_hidden on public.players(is_hidden);

grant update(is_hidden) on public.players to authenticated;
