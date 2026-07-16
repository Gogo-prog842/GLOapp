-- GLO: ukrywanie zawodników bez usuwania historii meczów
-- Uruchom w Supabase -> SQL Editor.

alter table public.players
    add column if not exists is_hidden boolean not null default false;

create index if not exists idx_players_is_hidden on public.players(is_hidden);

grant select on public.players to anon, authenticated;
grant update(is_hidden) on public.players to authenticated;

comment on column public.players.is_hidden is 'Gdy true, zawodnik jest ukryty z publicznych list/profilu/topów/wyszukiwarki, ale zostaje w historycznych składach meczów.';
