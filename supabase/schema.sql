-- ════════════════════════════════════════════════════════════════
--  STACK Intelligence — Supabase Schema
--  Run this in: Supabase Dashboard → SQL Editor → New query
-- ════════════════════════════════════════════════════════════════


-- ── ORGANIZATIONS ─────────────────────────────────────────────
-- Payroll providers, carriers, brokers, agencies
create table if not exists public.organizations (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  type          text check (type in ('payroll_provider','carrier','broker','agency','internal')),
  slug          text unique,
  created_at    timestamptz default now()
);
alter table public.organizations enable row level security;


-- ── USER PROFILES ─────────────────────────────────────────────
-- Extends Supabase auth.users
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text,
  role            text default 'viewer' check (role in ('owner','editor','viewer')),
  organization_id uuid references public.organizations(id),
  avatar_url      text,
  created_at      timestamptz default now()
);
alter table public.profiles enable row level security;

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ── RELATIONSHIPS ─────────────────────────────────────────────
-- Core STACK unit: a payroll provider → carrier pairing
create table if not exists public.relationships (
  id                  uuid primary key default gen_random_uuid(),
  payroll_provider    text not null,
  carrier             text not null,
  organization_id     uuid references public.organizations(id),
  status              text default 'active' check (status in ('active','onboarding','paused','exception','terminated')),
  stack_score         numeric(3,1) default 0 check (stack_score >= 0 and stack_score <= 5),
  s_score             numeric(3,1) default 0,  -- Signal
  t_score             numeric(3,1) default 0,  -- Transform
  a_score             numeric(3,1) default 0,  -- Assess
  c_score             numeric(3,1) default 0,  -- Check
  k_score             numeric(3,1) default 0,  -- Keys
  exception_count     integer default 0,
  last_submission_at  timestamptz,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);
alter table public.relationships enable row level security;


-- ── PAYROLL SUBMISSIONS ───────────────────────────────────────
create table if not exists public.payroll_submissions (
  id                uuid primary key default gen_random_uuid(),
  relationship_id   uuid references public.relationships(id) on delete cascade,
  organization_id   uuid references public.organizations(id),
  period_start      date,
  period_end        date,
  status            text default 'submitted' check (status in ('submitted','processing','exception','complete','skipped')),
  employee_count    integer,
  total_payroll     numeric(12,2),
  exception_count   integer default 0,
  submitted_by      uuid references auth.users(id),
  submitted_at      timestamptz default now(),
  processed_at      timestamptz
);
alter table public.payroll_submissions enable row level security;


-- ── STACK SCORE HISTORY ───────────────────────────────────────
-- Every time Linode recomputes scores, it writes a record here
create table if not exists public.stack_score_history (
  id              uuid primary key default gen_random_uuid(),
  relationship_id uuid references public.relationships(id) on delete cascade,
  stack_score     numeric(3,1),
  s_score         numeric(3,1),
  t_score         numeric(3,1),
  a_score         numeric(3,1),
  c_score         numeric(3,1),
  k_score         numeric(3,1),
  computed_by     text default 'linode',
  computed_at     timestamptz default now()
);
alter table public.stack_score_history enable row level security;


-- ── EXCEPTIONS ────────────────────────────────────────────────
create table if not exists public.exceptions (
  id              uuid primary key default gen_random_uuid(),
  submission_id   uuid references public.payroll_submissions(id) on delete cascade,
  relationship_id uuid references public.relationships(id),
  type            text,
  description     text,
  severity        text default 'medium' check (severity in ('low','medium','high','critical')),
  resolved        boolean default false,
  resolved_at     timestamptz,
  created_at      timestamptz default now()
);
alter table public.exceptions enable row level security;


-- ── ALERTS ────────────────────────────────────────────────────
-- Live monitoring triggers written by Linode, read by STACK dashboard
create table if not exists public.alerts (
  id              uuid primary key default gen_random_uuid(),
  relationship_id uuid references public.relationships(id),
  organization_id uuid references public.organizations(id),
  type            text check (type in ('score_drop','exception_spike','submission_late','onboarding_stalled','score_milestone')),
  title           text not null,
  body            text,
  severity        text default 'medium' check (severity in ('info','medium','high','critical')),
  read            boolean default false,
  created_at      timestamptz default now()
);
alter table public.alerts enable row level security;


-- ════════════════════════════════════════════════════════════════
--  RLS POLICIES
-- ════════════════════════════════════════════════════════════════

-- Profiles: users can read/update their own
create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Organizations: authenticated users can read
create policy "Authenticated users can view organizations"
  on public.organizations for select using (auth.role() = 'authenticated');

-- Relationships: authenticated users can read; only service role writes
create policy "Authenticated users can view relationships"
  on public.relationships for select using (auth.role() = 'authenticated');

-- Payroll submissions: org members can view their own
create policy "Users can view own org submissions"
  on public.payroll_submissions for select
  using (organization_id in (
    select organization_id from public.profiles where id = auth.uid()
  ));

-- STACK score history: all authenticated users can read
create policy "Authenticated users can view score history"
  on public.stack_score_history for select using (auth.role() = 'authenticated');

-- Exceptions: org members see their own
create policy "Users can view own org exceptions"
  on public.exceptions for select
  using (relationship_id in (
    select id from public.relationships where organization_id in (
      select organization_id from public.profiles where id = auth.uid()
    )
  ));

-- Alerts: org members see their own
create policy "Users can view own alerts"
  on public.alerts for select
  using (organization_id in (
    select organization_id from public.profiles where id = auth.uid()
  ));


-- ════════════════════════════════════════════════════════════════
--  SEED DATA — sample relationships for STACK dashboard
-- ════════════════════════════════════════════════════════════════

insert into public.organizations (name, type, slug) values
  ('PayComp Internal', 'internal', 'paycomp'),
  ('ADP',              'payroll_provider', 'adp'),
  ('QuickBooks',       'payroll_provider', 'quickbooks'),
  ('Paychex',          'payroll_provider', 'paychex'),
  ('Gusto',            'payroll_provider', 'gusto'),
  ('AmTrust',          'carrier', 'amtrust'),
  ('Travelers',        'carrier', 'travelers'),
  ('Omaha National',   'carrier', 'omaha-national'),
  ('ICW Group',        'carrier', 'icw-group'),
  ('Employers',        'carrier', 'employers')
on conflict (slug) do nothing;

insert into public.relationships
  (payroll_provider, carrier, status, stack_score, s_score, t_score, a_score, c_score, k_score, exception_count)
values
  ('ADP',         'AmTrust',        'active',      4.2, 4.5, 4.0, 4.3, 4.1, 4.1, 2),
  ('QuickBooks',  'Travelers',      'active',      1.8, 2.1, 1.5, 1.9, 1.8, 1.7, 11),
  ('Paychex',     'Omaha National', 'active',      3.7, 3.9, 3.5, 3.8, 3.6, 3.7, 4),
  ('Gusto',       'AmTrust',        'onboarding',  2.4, 2.8, 2.2, 2.4, 2.3, 2.3, 6),
  ('ADP',         'Travelers',      'active',      4.6, 4.8, 4.5, 4.6, 4.5, 4.6, 1),
  ('QuickBooks',  'ICW Group',      'exception',   1.2, 1.4, 1.0, 1.3, 1.1, 1.2, 18),
  ('Paychex',     'Employers',      'active',      3.1, 3.3, 2.9, 3.2, 3.0, 3.1, 5),
  ('Gusto',       'Travelers',      'onboarding',  2.9, 3.1, 2.7, 3.0, 2.8, 2.9, 7)
;
