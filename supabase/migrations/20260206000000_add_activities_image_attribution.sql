-- Migration: Add Unsplash attribution columns to activities for API compliance
-- Description: Store photographer name and profile URL when activity image comes from Unsplash

ALTER TABLE public.activities
ADD COLUMN IF NOT EXISTS image_attribution_name TEXT,
ADD COLUMN IF NOT EXISTS image_attribution_url TEXT;

COMMENT ON COLUMN public.activities.image_attribution_name IS 'Photographer full name for Unsplash attribution';
COMMENT ON COLUMN public.activities.image_attribution_url IS 'Photographer Unsplash profile URL for attribution link';
