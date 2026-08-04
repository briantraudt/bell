alter table public.profiles
  add column if not exists address text,
  add column if not exists text_scale numeric not null default 1.0,
  add column if not exists onboarding_completed boolean not null default false;

comment on column public.profiles.address is 'Private home address used only after a user books a provider.';
comment on column public.profiles.text_scale is 'User-selected app text scale from onboarding.';
comment on column public.profiles.onboarding_completed is 'Whether the first-run onboarding flow has been completed.';
