-- Migration: Add dating profile prompt fields
-- Description: Adds simple_pleasure, rig_info, and dating_looks_like fields for dating profiles

-- Add new columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN simple_pleasure TEXT CHECK (LENGTH(simple_pleasure) <= 500),
ADD COLUMN rig_info TEXT CHECK (LENGTH(rig_info) <= 300),
ADD COLUMN dating_looks_like TEXT CHECK (LENGTH(dating_looks_like) <= 500);

-- Add comments for documentation
COMMENT ON COLUMN public.profiles.simple_pleasure IS 'Answer to "My simple pleasure" prompt';
COMMENT ON COLUMN public.profiles.rig_info IS 'Vehicle/rig description (e.g., "2019 Sprinter 144, Self-Converted")';
COMMENT ON COLUMN public.profiles.dating_looks_like IS 'Answer to "Dating me looks like" prompt';
