-- Migration: Add dating preference columns to profiles
-- Description: Store preferred age range and max distance for discovery filtering

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS preferred_min_age INT CHECK (preferred_min_age IS NULL OR (preferred_min_age >= 18 AND preferred_min_age <= 80)),
    ADD COLUMN IF NOT EXISTS preferred_max_age INT CHECK (preferred_max_age IS NULL OR (preferred_max_age >= 18 AND preferred_max_age <= 80)),
    ADD COLUMN IF NOT EXISTS preferred_max_distance_miles INT CHECK (preferred_max_distance_miles IS NULL OR (preferred_max_distance_miles >= 1 AND preferred_max_distance_miles <= 500));

COMMENT ON COLUMN public.profiles.preferred_min_age IS 'Minimum age for dating discovery (18-80)';
COMMENT ON COLUMN public.profiles.preferred_max_age IS 'Maximum age for dating discovery (18-80)';
COMMENT ON COLUMN public.profiles.preferred_max_distance_miles IS 'Maximum distance in miles for dating discovery (1-500)';
