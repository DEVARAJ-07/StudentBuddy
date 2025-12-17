-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";

-- 1. Mentors Table
-- Stores mentor profiles. 'created_by' references the user who added the mentor (if applicable).
create table public.mentors (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  specialization text not null, -- e.g., 'Physics', 'Math', 'Career Guidance'
  image_url text, -- URL to avatar image
  created_by uuid references auth.users(id) on delete set null, -- User who created this mentor persona
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Tests Table
-- Stores available tests/quizzes.
create table public.tests (
  id uuid primary key default uuid_generate_v4(),
  title text not null, -- e.g., 'Chapter 5: Thermodynamics'
  subject text not null,
  total_marks integer not null,
  duration_minutes integer, -- Optional: duration of the test
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Test Results Table
-- Stores the scores obtained by students.
create table public.test_results (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) not null,
  test_id uuid references public.tests(id) not null,
  marks_obtained integer not null,
  completed_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Daily Streaks Table
-- Tracks daily login/activity for the heatmap.
-- A simple log of dates when the user was active.
create table public.daily_streaks (
    id uuid primary key default uuid_generate_v4 (),
    user_id uuid references auth.users (id) not null,
    activity_date date not null default CURRENT_DATE,
    intensity integer default 1, -- 1 to 4 scale for heatmap intensity
    unique (user_id, activity_date) -- Prevent duplicate entries for the same day
);

-- 5. Recommendations Table
-- Stores content (Videos/Notes) linked to Mentors.
create table public.recommendations (
  id uuid primary key default uuid_generate_v4(),
  mentor_id uuid references public.mentors(id) on delete cascade not null,
  title text not null, -- e.g., 'Intro to Calculus'
  type text check (type in ('video', 'note')) not null,
  url text not null, -- Link to resource
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Row Level Security (RLS) Policies (Basic)

-- Enable RLS
alter table public.mentors enable row level security;

alter table public.tests enable row level security;

alter table public.test_results enable row level security;

alter table public.daily_streaks enable row level security;

alter table public.recommendations enable row level security;

-- Policies
-- Mentors: Everyone can read. Authenticated users can create.
create policy "Mentors are viewable by everyone" on public.mentors for
select using (true);

create policy "Users can create mentors" on public.mentors for
insert
with
    check (auth.uid () = created_by);

-- Tests: Everyone can read.
create policy "Tests are viewable by everyone" on public.tests for
select using (true);

-- Test Results: Users can see only their own results.
create policy "Users can view own results" on public.test_results for
select using (auth.uid () = user_id);

create policy "Users can insert own results" on public.test_results for
insert
with
    check (auth.uid () = user_id);

-- Streaks: Users can see only their own streaks.
create policy "Users can view own streaks" on public.daily_streaks for
select using (auth.uid () = user_id);

create policy "Users can insert own streaks" on public.daily_streaks for
insert
with
    check (auth.uid () = user_id);

-- Recommendations: Everyone can read.
create policy "Recommendations are viewable by everyone" on public.recommendations for
select using (true);