-- ==============================================================================
-- V-Hab Upper-Limb Rehabilitation: Supabase Database Schema & RLS Security
-- Run this complete script in the Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Exercise Sessions Table
CREATE TABLE IF NOT EXISTS public.exercise_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  exercise_type TEXT NOT NULL,
  score INTEGER NOT NULL,
  accuracy NUMERIC NOT NULL,
  duration_seconds INTEGER NOT NULL,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for efficient querying of recent sessions by user
CREATE INDEX IF NOT EXISTS idx_exercise_sessions_user_created 
  ON public.exercise_sessions(user_id, created_at DESC);

-- 3. Exercise Progress Table
CREATE TABLE IF NOT EXISTS public.exercise_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  best_score INTEGER DEFAULT 0,
  best_accuracy NUMERIC DEFAULT 0,
  total_attempts INTEGER DEFAULT 0,
  completed_attempts INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_user_exercise UNIQUE (user_id, exercise_name)
);

-- Index for fast user progress lookup
CREATE INDEX IF NOT EXISTS idx_exercise_progress_user 
  ON public.exercise_progress(user_id);

-- ==============================================================================
-- 4. Enable Row Level Security (RLS) on all tables
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_progress ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 5. Row Level Security Policies
-- Users can only read, insert, and update their own data
-- ==============================================================================

-- Profiles Policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Exercise Sessions Policies
DROP POLICY IF EXISTS "Users can read own exercise sessions" ON public.exercise_sessions;
CREATE POLICY "Users can read own exercise sessions"
  ON public.exercise_sessions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own exercise sessions" ON public.exercise_sessions;
CREATE POLICY "Users can insert own exercise sessions"
  ON public.exercise_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Exercise Progress Policies
DROP POLICY IF EXISTS "Users can read own progress" ON public.exercise_progress;
CREATE POLICY "Users can read own progress"
  ON public.exercise_progress FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own progress" ON public.exercise_progress;
CREATE POLICY "Users can insert own progress"
  ON public.exercise_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own progress" ON public.exercise_progress;
CREATE POLICY "Users can update own progress"
  ON public.exercise_progress FOR UPDATE
  USING (auth.uid() = user_id);

-- ==============================================================================
-- 6. Trigger: Automatically create a profile on user sign up
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, created_at)
  VALUES (
    new.id,
    COALESCE(
      new.raw_user_meta_data->>'name',
      new.raw_user_meta_data->>'full_name',
      split_part(new.email, '@', 1)
    ),
    new.email,
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
