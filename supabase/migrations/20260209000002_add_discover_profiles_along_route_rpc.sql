-- Server-side distance filtering for Discover profiles along a user's travel route.
-- Returns profiles near the user's current location OR near any of their travel stops.
-- Uses the Haversine formula to compute great-circle distance in miles.
-- Current location (p_user_lat/p_user_lon) is nullable — if NULL, only travel stops are checked.

CREATE OR REPLACE FUNCTION discover_profiles_along_route(
    p_user_id UUID,
    p_user_lat DOUBLE PRECISION DEFAULT NULL,
    p_user_lon DOUBLE PRECISION DEFAULT NULL,
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
          -- Near current location (if provided)
          (
              p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL AND
              (
                  3959.0 * 2 * ASIN(SQRT(
                      POWER(SIN(RADIANS(p.latitude - p_user_lat) / 2), 2) +
                      COS(RADIANS(p_user_lat)) * COS(RADIANS(p.latitude)) *
                      POWER(SIN(RADIANS(p.longitude - p_user_lon) / 2), 2)
                  ))
              ) <= p_max_distance_miles
          )
          OR
          -- Near any travel stop with coordinates
          EXISTS (
              SELECT 1
              FROM travel_schedule ts
              WHERE ts.user_id = p_user_id
                AND ts.latitude IS NOT NULL
                AND ts.longitude IS NOT NULL
                AND (
                    3959.0 * 2 * ASIN(SQRT(
                        POWER(SIN(RADIANS(p.latitude - ts.latitude) / 2), 2) +
                        COS(RADIANS(ts.latitude)) * COS(RADIANS(p.latitude)) *
                        POWER(SIN(RADIANS(p.longitude - ts.longitude) / 2), 2)
                    ))
                ) <= p_max_distance_miles
          )
      )
    LIMIT p_limit;
$$;
