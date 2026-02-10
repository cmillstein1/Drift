-- Server-side distance filtering for Discover profiles.
-- Uses the Haversine formula to compute great-circle distance in miles.
-- Returns profiles from the `profiles` table within the specified radius.
-- Profiles without coordinates are excluded (can't verify proximity).

CREATE OR REPLACE FUNCTION discover_profiles_nearby(
    p_user_id UUID,
    p_user_lat DOUBLE PRECISION,
    p_user_lon DOUBLE PRECISION,
    p_max_distance_miles INT DEFAULT 50,
    p_looking_for TEXT DEFAULT 'friends',
    p_exclude_ids UUID[] DEFAULT '{}',
    p_limit INT DEFAULT 40
)
RETURNS SETOF profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT p.*
    FROM profiles p
    WHERE p.id != p_user_id
      AND p.onboarding_completed = true
      AND NOT (p.id = ANY(p_exclude_ids))
      AND (
          CASE p_looking_for
              WHEN 'dating' THEN p.looking_for IN ('dating', 'both')
              WHEN 'friends' THEN p.looking_for IN ('friends', 'both')
              ELSE TRUE
          END
      )
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
      AND (
          3959.0 * 2 * ASIN(SQRT(
              POWER(SIN(RADIANS(p.latitude - p_user_lat) / 2), 2) +
              COS(RADIANS(p_user_lat)) * COS(RADIANS(p.latitude)) *
              POWER(SIN(RADIANS(p.longitude - p_user_lon) / 2), 2)
          ))
      ) <= p_max_distance_miles
    LIMIT p_limit;
$$;
