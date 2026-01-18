-- Migration: Create Profiles and Travel Schedule Tables
-- Description: Core user profile data extending Supabase auth

-- User Profiles Table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    birthday DATE,
    -- age is computed client-side from birthday
    bio TEXT CHECK (LENGTH(bio) <= 500),
    avatar_url TEXT,
    photos TEXT[] DEFAULT '{}',
    location TEXT,
    verified BOOLEAN DEFAULT FALSE,

    -- Profile Details
    lifestyle TEXT CHECK (lifestyle IN ('van_life', 'digital_nomad', 'rv_life', 'traveler')),
    travel_pace TEXT CHECK (travel_pace IN ('slow', 'moderate', 'fast')),
    next_destination TEXT,
    travel_dates TEXT,
    interests TEXT[] DEFAULT '{}',

    -- Discovery Settings
    looking_for TEXT CHECK (looking_for IN ('dating', 'friends', 'both')) DEFAULT 'both',
    friends_only BOOLEAN DEFAULT FALSE,
    orientation TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    onboarding_completed BOOLEAN DEFAULT FALSE
);

-- Indexes for profiles
CREATE INDEX idx_profiles_looking_for ON public.profiles(looking_for);
CREATE INDEX idx_profiles_friends_only ON public.profiles(friends_only);
CREATE INDEX idx_profiles_onboarding ON public.profiles(onboarding_completed);

-- Travel Schedule Table
CREATE TABLE public.travel_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    location TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_travel_schedule_user ON public.travel_schedule(user_id);
CREATE INDEX idx_travel_schedule_dates ON public.travel_schedule(start_date, end_date);

-- RLS Policies for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS for travel_schedule
ALTER TABLE public.travel_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all travel schedules" ON public.travel_schedule
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own travel schedule" ON public.travel_schedule
    FOR ALL USING (auth.uid() = user_id);

-- Trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Enable Realtime for profiles (for online status)
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
