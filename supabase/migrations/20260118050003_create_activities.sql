-- Migration: Create Activities Tables
-- Description: Activities, attendees with realtime updates

-- Activity Categories
CREATE TYPE activity_category AS ENUM ('outdoor', 'work', 'social', 'food_drink', 'wellness', 'adventure');

-- Activities Table
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category activity_category NOT NULL,
    location TEXT NOT NULL,
    exact_location TEXT, -- Revealed after joining
    image_url TEXT,

    -- Schedule
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ,
    duration_minutes INTEGER,

    -- Capacity
    max_attendees INTEGER NOT NULL DEFAULT 10,
    current_attendees INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    cancelled_at TIMESTAMPTZ
);

CREATE INDEX idx_activities_host ON public.activities(host_id);
CREATE INDEX idx_activities_starts ON public.activities(starts_at);
CREATE INDEX idx_activities_category ON public.activities(category);
CREATE INDEX idx_activities_cancelled ON public.activities(cancelled_at);

-- Activity Attendees
CREATE TABLE public.activity_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'cancelled')) DEFAULT 'confirmed',
    joined_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_attendee UNIQUE (activity_id, user_id)
);

CREATE INDEX idx_attendees_activity ON public.activity_attendees(activity_id);
CREATE INDEX idx_attendees_user ON public.activity_attendees(user_id);

-- RLS Policies
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_attendees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view non-cancelled activities" ON public.activities
    FOR SELECT USING (cancelled_at IS NULL);

CREATE POLICY "Users can create activities" ON public.activities
    FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Hosts can update their activities" ON public.activities
    FOR UPDATE USING (auth.uid() = host_id);

CREATE POLICY "Hosts can delete their activities" ON public.activities
    FOR DELETE USING (auth.uid() = host_id);

-- Attendees policies
CREATE POLICY "Anyone can view attendees" ON public.activity_attendees
    FOR SELECT USING (true);

CREATE POLICY "Users can join activities" ON public.activity_attendees
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave activities" ON public.activity_attendees
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can update their attendance" ON public.activity_attendees
    FOR UPDATE USING (auth.uid() = user_id);

-- Update attendee count trigger
CREATE OR REPLACE FUNCTION public.update_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.activities
        SET current_attendees = current_attendees + 1
        WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.activities
        SET current_attendees = current_attendees - 1
        WHERE id = OLD.activity_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_attendee_change
    AFTER INSERT OR DELETE ON public.activity_attendees
    FOR EACH ROW EXECUTE FUNCTION public.update_attendee_count();

-- Update activity timestamp trigger
CREATE TRIGGER activities_updated_at
    BEFORE UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.activities;
ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_attendees;
