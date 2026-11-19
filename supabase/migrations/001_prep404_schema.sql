-- Prep404 Supabase PostgreSQL Schema & Row Level Security
-- Run in your Supabase SQL Editor to persist authenticated candidate profiles,
-- exam history, and AETHER AI finger-telemetry answer locks.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null,
  phone text,
  avatar_url text,
  preferred_university_track text,
  current_academic_level text,
  study_medium text,
  nctb_version text,
  english_curriculum text,
  academic_batch text,
  institution_name text,
  division_name text,
  district_name text,
  ssc_gpa text,
  hsc_gpa text,
  study_streak_days integer not null default 0,
  preferred_language text,
  preferred_theme text,
  target_selections jsonb not null default '{}'::jsonb,
  profile_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Idempotent upgrade for existing Prep404 Supabase projects
alter table public.profiles add column if not exists preferred_university_track text;
alter table public.profiles add column if not exists current_academic_level text;
alter table public.profiles add column if not exists study_medium text;
alter table public.profiles add column if not exists nctb_version text;
alter table public.profiles add column if not exists english_curriculum text;
alter table public.profiles add column if not exists academic_batch text;
alter table public.profiles add column if not exists institution_name text;
alter table public.profiles add column if not exists division_name text;
alter table public.profiles add column if not exists district_name text;
alter table public.profiles add column if not exists ssc_gpa text;
alter table public.profiles add column if not exists hsc_gpa text;
alter table public.profiles add column if not exists study_streak_days integer not null default 0;
alter table public.profiles add column if not exists preferred_language text;
alter table public.profiles add column if not exists preferred_theme text;

alter table public.profiles enable row level security;

create policy "Users can view their own Prep404 profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert their own Prep404 profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own Prep404 profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create table if not exists public.exam_history (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  exam_slug text not null,
  title text not null,
  track text not null,
  mode text not null,
  score numeric not null default 0,
  total_questions integer not null,
  correct_count integer not null default 0,
  wrong_count integer not null default 0,
  unanswered_count integer not null default 0,
  time_taken_seconds integer not null default 0,
  payload jsonb not null,
  submitted_at timestamptz not null default now()
);

alter table public.exam_history enable row level security;

create policy "Users can view their own exam history"
  on public.exam_history for select
  using (auth.uid() = user_id);

create policy "Users can insert their own exam history"
  on public.exam_history for insert
  with check (auth.uid() = user_id);

create table if not exists public.telemetry_answer_locks (
  event_id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id text not null,
  subject_name text not null,
  topic_id text,
  read_time_ms integer not null,
  think_time_ms integer not null,
  total_time_ms integer not null,
  touch_interaction_count integer not null default 1,
  touch_cadence_label text,
  classification text not null,
  locked_option_id text not null,
  is_correct boolean not null,
  touch_pattern jsonb,
  recorded_at timestamptz not null default now()
);

alter table public.telemetry_answer_locks enable row level security;

create policy "Users can view their own telemetry locks"
  on public.telemetry_answer_locks for select
  using (auth.uid() = user_id);

create policy "Users can insert their own telemetry locks"
  on public.telemetry_answer_locks for insert
  with check (auth.uid() = user_id);
