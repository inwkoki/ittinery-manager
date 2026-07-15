-- Run this in the Supabase SQL Editor for project pyeeqlnnzsencnitobwo
-- (Dashboard -> SQL Editor -> New query -> paste -> Run)
-- Safe to re-run: every step below is idempotent.

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid,
  item_date date not null,
  start_time time,
  end_time time,
  category text default 'activity',
  title text not null,
  place_name text,
  place_link text,
  address text,
  opening_hours text,
  opening_hours_periods text,
  photo_url text,
  flight_number text,
  checkout_date date,
  needs_booking boolean default false,
  remind_days_before integer,
  is_booked boolean default false,
  reservation_name text,
  confirmation_code text,
  price numeric,
  currency text default 'USD',
  notes text,
  ticket_data text,
  sort_order bigint default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Backfill columns for tables created before this version of the schema.
alter table public.itinerary_items add column if not exists trip_id uuid;
alter table public.itinerary_items add column if not exists address text;
alter table public.itinerary_items add column if not exists opening_hours text;
alter table public.itinerary_items add column if not exists opening_hours_periods text;
alter table public.itinerary_items add column if not exists photo_url text;
alter table public.itinerary_items add column if not exists flight_number text;
alter table public.itinerary_items add column if not exists checkout_date date;
alter table public.itinerary_items add column if not exists needs_booking boolean default false;
alter table public.itinerary_items add column if not exists remind_days_before integer;
alter table public.itinerary_items add column if not exists is_booked boolean default false;
alter table public.itinerary_items add column if not exists sort_order bigint default 0;

-- Link items to trips (cascade delete so removing a trip clears its items).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'itinerary_items_trip_id_fkey'
  ) then
    alter table public.itinerary_items
      add constraint itinerary_items_trip_id_fkey
      foreign key (trip_id) references public.trips(id) on delete cascade;
  end if;
end $$;

create index if not exists itinerary_items_trip_id_idx on public.itinerary_items(trip_id);

-- If items already exist without a trip (from before trips existed),
-- group them into a single "My Trip" so nothing gets orphaned/hidden.
do $$
declare default_trip_id uuid;
begin
  if exists (select 1 from public.itinerary_items where trip_id is null) then
    insert into public.trips (name) values ('My Trip') returning id into default_trip_id;
    update public.itinerary_items set trip_id = default_trip_id where trip_id is null;
  end if;
end $$;

-- Keep updated_at fresh on every edit
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_itinerary_items_updated_at on public.itinerary_items;
create trigger trg_itinerary_items_updated_at
before update on public.itinerary_items
for each row execute function public.set_updated_at();

drop trigger if exists trg_trips_updated_at on public.trips;
create trigger trg_trips_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

-- =====================================================================
-- Optional auth: per-user ownership
-- =====================================================================
-- Add a user_id column so signed-in users' trips are private to them.
-- Legacy rows (created before you enabled auth) keep user_id = NULL and
-- stay accessible to the anonymous/publishable key, so nothing you already
-- have disappears. New rows created while signed in are stamped with the
-- user's id and are only visible/editable by that user.
alter table public.trips add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.itinerary_items add column if not exists user_id uuid references auth.users(id) on delete cascade;

create index if not exists trips_user_id_idx on public.trips(user_id);
create index if not exists itinerary_items_user_id_idx on public.itinerary_items(user_id);

-- Row Level Security
--   * anonymous key (not signed in): can read/write only the shared legacy
--     rows where user_id IS NULL.
--   * signed-in user: can read/write only their own rows (user_id = auth.uid()).
alter table public.itinerary_items enable row level security;
alter table public.trips enable row level security;

-- Drop the previous wide-open policies if they exist.
drop policy if exists "public read" on public.itinerary_items;
drop policy if exists "public insert" on public.itinerary_items;
drop policy if exists "public update" on public.itinerary_items;
drop policy if exists "public delete" on public.itinerary_items;
drop policy if exists "public read" on public.trips;
drop policy if exists "public insert" on public.trips;
drop policy if exists "public update" on public.trips;
drop policy if exists "public delete" on public.trips;

drop policy if exists "own or shared read" on public.trips;
create policy "own or shared read" on public.trips for select
  using (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared insert" on public.trips;
create policy "own or shared insert" on public.trips for insert
  with check (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared update" on public.trips;
create policy "own or shared update" on public.trips for update
  using (user_id is null or user_id = auth.uid())
  with check (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared delete" on public.trips;
create policy "own or shared delete" on public.trips for delete
  using (user_id is null or user_id = auth.uid());

drop policy if exists "own or shared read" on public.itinerary_items;
create policy "own or shared read" on public.itinerary_items for select
  using (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared insert" on public.itinerary_items;
create policy "own or shared insert" on public.itinerary_items for insert
  with check (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared update" on public.itinerary_items;
create policy "own or shared update" on public.itinerary_items for update
  using (user_id is null or user_id = auth.uid())
  with check (user_id is null or user_id = auth.uid());
drop policy if exists "own or shared delete" on public.itinerary_items;
create policy "own or shared delete" on public.itinerary_items for delete
  using (user_id is null or user_id = auth.uid());
