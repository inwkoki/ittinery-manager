-- Run this once in the Supabase SQL Editor for project pyeeqlnnzsencnitobwo
-- (Dashboard -> SQL Editor -> New query -> paste -> Run)

create table if not exists public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  item_date date not null,
  start_time time,
  end_time time,
  category text default 'activity',
  title text not null,
  place_name text,
  place_link text,
  reservation_name text,
  confirmation_code text,
  price numeric,
  currency text default 'USD',
  notes text,
  ticket_data text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

-- Row Level Security
-- The app connects with the public "publishable" key, which has no user
-- login attached, so RLS policies here are wide open (anyone with the
-- URL+key can read/write). That's fine for a private single-user tool
-- that you don't share, but do NOT reuse this schema for anything with
-- other users' data without adding real auth + tighter policies.
alter table public.itinerary_items enable row level security;

drop policy if exists "public read" on public.itinerary_items;
create policy "public read" on public.itinerary_items
  for select using (true);

drop policy if exists "public insert" on public.itinerary_items;
create policy "public insert" on public.itinerary_items
  for insert with check (true);

drop policy if exists "public update" on public.itinerary_items;
create policy "public update" on public.itinerary_items
  for update using (true) with check (true);

drop policy if exists "public delete" on public.itinerary_items;
create policy "public delete" on public.itinerary_items
  for delete using (true);
