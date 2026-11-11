-- Daily Logic leaderboard. Run once in the Supabase SQL editor.
-- The launch date below must match LAUNCH in logic/index.html (new Date(2026, 10, 7) = 2026-11-07).

create table if not exists public.scores (
  id          bigint generated always as identity primary key,
  day         int  not null check (day >= 1),
  game        text not null check (game in ('sectors', 'binary', 'weights')),
  initials    text not null check (initials ~ '^[A-Z]{1,3}$'),
  ms          int  not null check (ms between 5000 and 3600000),
  device      text not null check (char_length(device) between 8 and 64),
  created_at  timestamptz not null default now(),
  unique (day, game, device)
);

create index if not exists scores_day_game_ms on public.scores (day, game, ms, created_at);

-- Today's puzzle number, counted from the launch date in America/New_York.
create or replace function public.daily_logic_day()
returns int language sql stable
as $$ select ((now() at time zone 'America/New_York')::date - date '2026-11-07') + 1 $$;

alter table public.scores enable row level security;

drop policy if exists "scores read" on public.scores;
drop policy if exists "scores insert current day" on public.scores;

create policy "scores read" on public.scores
  for select to anon using (true);

-- Players see "today" in their own time zone, which can be one day either side of New York's.
-- Anything older than that is rejected, so past days cannot be backfilled.
create policy "scores insert current day" on public.scores
  for insert to anon
  with check (day between public.daily_logic_day() - 1 and public.daily_logic_day() + 1);

-- anon may read scores (not device ids) and add rows. No update, no delete.
revoke all on public.scores from anon;
grant select (day, game, initials, ms, created_at) on public.scores to anon;
grant insert (day, game, initials, ms, device) on public.scores to anon;
