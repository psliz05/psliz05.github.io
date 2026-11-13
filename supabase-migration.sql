-- Adds the flight-course scoreboard (game = 'flight') to an existing Daily Logic / ski leaderboard table.
-- Run once in the Supabase SQL editor. Safe to run again: every step drops and recreates by name.
-- Row level security, the read policy, the insert-current-day policy and the column grants are not touched.

begin;

-- 1. Allow the new game id (also covers a table created before the ski scoreboard existed).
alter table public.scores drop constraint if exists scores_game_check;
alter table public.scores add constraint scores_game_check
  check (game in ('sectors', 'binary', 'weights', 'ski', 'flight'));

-- 2. One row per device per puzzle per day, except ski runs and flights, which may be posted again
--    when you beat your own time. (The oldest version of the table used a plain unique constraint.)
alter table public.scores drop constraint if exists scores_day_game_device_key;
drop index if exists public.scores_one_per_device;
create unique index scores_one_per_device on public.scores (day, game, device)
  where game not in ('ski', 'flight');

commit;
