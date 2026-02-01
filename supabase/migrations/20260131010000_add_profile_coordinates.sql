-- Add latitude/longitude to profiles for distance-based filtering (e.g. Nearby Friends).
-- When a user sets their location (e.g. via map picker), we store coordinates so we can
-- filter discover results by max distance.
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

COMMENT ON COLUMN public.profiles.latitude IS 'Latitude of profile location when set via map or geocoding';
COMMENT ON COLUMN public.profiles.longitude IS 'Longitude of profile location when set via map or geocoding';
