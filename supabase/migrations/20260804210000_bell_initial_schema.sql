create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null,
  last_name text not null default '',
  phone text,
  city text,
  read_aloud boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.family_members (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, relationship text, phone text, can_view_activity boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.providers (
  id uuid primary key default gen_random_uuid(), name text not null, trade text not null,
  rating numeric(2,1), jobs_completed integer not null default 0, years_experience integer,
  background_checked_at date, insured_amount_cents bigint, active boolean not null default true
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  provider_id uuid references public.providers(id), service text not null, scheduled_at timestamptz not null,
  price_cents integer not null, status text not null check (status in ('requested','booked','on_the_way','in_progress','finished','cancelled')),
  created_at timestamptz not null default now()
);

create table public.reminders (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, detail text, scheduled_at timestamptz not null, enabled boolean not null default true,
  last_taken_at timestamptz, created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.family_members enable row level security;
alter table public.providers enable row level security;
alter table public.bookings enable row level security;
alter table public.reminders enable row level security;

create policy "profiles own rows" on public.profiles for all to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "family own rows" on public.family_members for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "providers readable" on public.providers for select to authenticated using (active = true);
create policy "bookings own rows" on public.bookings for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "reminders own rows" on public.reminders for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
