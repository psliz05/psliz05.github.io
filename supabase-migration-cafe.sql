-- Adds the café scoreboard (game = 'cafe', best tips in one three-minute shift, stored in cents in ms)
-- to an existing scores table. Run once in the Supabase SQL editor. Safe to run again: every step
-- drops and recreates by name. Row level security, both policies and the column grants are not touched.

begin;

-- 1. Allow the new game id.
alter table public.scores drop constraint if exists scores_game_check;
alter table public.scores add constraint scores_game_check
  check (game in ('sectors', 'binary', 'weights', 'ski', 'flight', 'cafe'));

-- 2. Times stay between 5 s and 1 h; café tips are cents, from $0.00 to $1,000.00.
alter table public.scores drop constraint if exists scores_ms_check;
alter table public.scores add constraint scores_ms_check
  check ((game = 'cafe' and ms between 0 and 100000) or (game <> 'cafe' and ms between 5000 and 3600000));

-- 3. One row per device per puzzle per day, except ski runs, flights and café shifts, which may be
--    posted again when you beat your own best.
drop index if exists public.scores_one_per_device;
create unique index scores_one_per_device on public.scores (day, game, device)
  where game not in ('ski', 'flight', 'cafe');

commit;
