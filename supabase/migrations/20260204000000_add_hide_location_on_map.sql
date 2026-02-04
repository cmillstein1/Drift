-- Add privacy option: hide my location on the Nearby map
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS hide_location_on_map BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN public.profiles.hide_location_on_map IS 'When true, user does not appear on the Nearby map (for themselves and others).';
