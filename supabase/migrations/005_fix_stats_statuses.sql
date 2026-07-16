-- ============================================================
-- GLO — naprawa niespójnych statusów i typów meczów
-- Uruchom w Supabase SQL Editor, jeśli w bazie masz stare wartości
-- typu status='finished' albo match_type='regular'.
-- Kod strony obsługuje te wartości, ale ta migracja porządkuje bazę.
-- ============================================================

-- 1) Wszystkie stare nazwy zakończonego meczu zamień na standard: completed.
UPDATE matches
SET status = 'completed'
WHERE lower(coalesce(status, '')) IN ('finished', 'done', 'played', 'closed');

-- 2) Jeżeli mecz ma wpisany wynik, ale status nie jest ani completed, ani scheduled,
-- potraktuj go jako zakończony. To naprawia przypadki, gdzie gole były widoczne
-- w historii, ale nie wliczały się do tabeli zawodników.
UPDATE matches
SET status = 'completed'
WHERE home_score IS NOT NULL
  AND away_score IS NOT NULL
  AND lower(coalesce(status, '')) NOT IN ('completed', 'scheduled', 'cancelled', 'canceled');

-- 3) Stare/ręczne typy meczów ligowych zamień na standard: league.
UPDATE matches
SET match_type = 'league'
WHERE match_type IS NULL
   OR trim(match_type) = ''
   OR lower(match_type) IN ('regular', 'liga', 'normal', 'season', 'match', 'mecz');
