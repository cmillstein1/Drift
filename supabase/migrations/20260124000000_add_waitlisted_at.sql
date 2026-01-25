-- Migration: Add waitlisted_at column to profiles
-- Description: Tracks when a user joined the waitlist (null = not on waitlist).

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS waitlisted_at TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.waitlisted_at IS 'When the user joined the waitlist; null if not waitlisted';

CREATE INDEX IF NOT EXISTS idx_profiles_waitlisted_at ON public.profiles(waitlisted_at)
WHERE waitlisted_at IS NOT NULL;
