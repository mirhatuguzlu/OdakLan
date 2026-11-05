-- Step 5: accounts. One public profile per auth user, created by trigger.
-- Minimal PII: only a nickname lives here; the email stays in auth.users.
-- Game tables (sessions, wallet, clans) come with server validation in steps 6-7.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
    check (char_length(display_name) between 3 and 20
           and display_name !~ '[[:cntrl:]]'),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Own row only for now; step 7 lets clan mates see each other's nicknames.
create policy "profiles: read own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);

create policy "profiles: update own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Clients may only rename; rows are created by the trigger, deleted with the user.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

-- Random nickname instead of the Google name, so no real name is stored.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, 'Odakçı' || lpad((floor(random() * 10000))::int::text, 4, '0'));
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
