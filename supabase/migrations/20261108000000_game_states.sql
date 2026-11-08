-- Step 6: the whole game state per player, written ONLY by the `game` Edge
-- Function (service role) after applying the shared rules with server time.
-- Clients have no grants at all: they read and act through the function.

create table public.game_states (
  user_id uuid primary key references auth.users (id) on delete cascade,
  state jsonb not null check (jsonb_typeof(state) = 'object'),
  version integer not null default 1 check (version > 0),
  updated_at timestamptz not null default now()
);

alter table public.game_states enable row level security;
-- No policies on purpose: with RLS on and no policy, anon/authenticated see
-- nothing even if a grant slips in later. Service role bypasses RLS.
revoke all on public.game_states from anon, authenticated;
