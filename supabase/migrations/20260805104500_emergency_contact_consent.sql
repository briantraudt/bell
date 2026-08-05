alter table public.family_members
  add column if not exists consent_status text not null default 'pending',
  add column if not exists consent_requested_at timestamptz,
  add column if not exists consented_at timestamptz,
  add column if not exists declined_at timestamptz;

alter table public.family_members
  drop constraint if exists family_members_consent_status_check;

alter table public.family_members
  add constraint family_members_consent_status_check
  check (consent_status in ('pending','accepted','declined'));

drop index if exists public.family_members_user_phone_unique;
create unique index family_members_user_phone_unique
  on public.family_members (user_id, phone);

create index if not exists family_members_pending_phone_idx
  on public.family_members (phone, created_at desc)
  where consent_status = 'pending';
