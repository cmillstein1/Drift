-- Migration: Add Unsplash attribution columns to community_posts
-- Description: Store photographer name and profile URL when post image comes from Unsplash

ALTER TABLE public.community_posts
ADD COLUMN IF NOT EXISTS image_attribution_name TEXT,
ADD COLUMN IF NOT EXISTS image_attribution_url TEXT;

COMMENT ON COLUMN public.community_posts.image_attribution_name IS 'Photographer full name for Unsplash attribution';
COMMENT ON COLUMN public.community_posts.image_attribution_url IS 'Photographer Unsplash profile URL for attribution link';
