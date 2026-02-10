-- Upgrade discover_profiles_along_route to cross-reference BOTH users' travel stops.
-- Now matches profiles based on ANY combination of:
--   1. My location        ↔ their profile location
--   2. My travel stops    ↔ their profile location
--   3. My location        ↔ their travel stops
--   4. My travel stops    ↔ their travel stops

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
      AND (
          -- 1. My location ↔ their profile location
          (
              p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL AND
              p.latitude IS NOT NULL AND p.longitude IS NOT NULL AND
              (
                  3959.0 * 2 * ASIN(SQRT(
                      POWER(SIN(RADIANS(p.latitude - p_user_lat) / 2), 2) +
                      COS(RADIANS(p_user_lat)) * COS(RADIANS(p.latitude)) *
                      POWER(SIN(RADIANS(p.longitude - p_user_lon) / 2), 2)
                  ))
              ) <= p_max_distance_miles
          )
          OR
          -- 2. My travel stops ↔ their profile location
          (
              p.latitude IS NOT NULL AND p.longitude IS NOT NULL AND
              EXISTS (
                  SELECT 1
                  FROM travel_schedule my_ts
                  WHERE my_ts.user_id = p_user_id
                    AND my_ts.latitude IS NOT NULL
                    AND my_ts.longitude IS NOT NULL
                    AND (
                        3959.0 * 2 * ASIN(SQRT(
                            POWER(SIN(RADIANS(p.latitude - my_ts.latitude) / 2), 2) +
                            COS(RADIANS(my_ts.latitude)) * COS(RADIANS(p.latitude)) *
                            POWER(SIN(RADIANS(p.longitude - my_ts.longitude) / 2), 2)
                        ))
                    ) <= p_max_distance_miles
              )
          )
          OR
          -- 3. My location ↔ their travel stops
          (
              p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL AND
              EXISTS (
                  SELECT 1
                  FROM travel_schedule their_ts
                  WHERE their_ts.user_id = p.id
                    AND their_ts.latitude IS NOT NULL
                    AND their_ts.longitude IS NOT NULL
                    AND (
                        3959.0 * 2 * ASIN(SQRT(
                            POWER(SIN(RADIANS(their_ts.latitude - p_user_lat) / 2), 2) +
                            COS(RADIANS(p_user_lat)) * COS(RADIANS(their_ts.latitude)) *
                            POWER(SIN(RADIANS(their_ts.longitude - p_user_lon) / 2), 2)
                        ))
                    ) <= p_max_distance_miles
              )
          )
          OR
          -- 4. My travel stops ↔ their travel stops
          EXISTS (
              SELECT 1
              FROM travel_schedule my_ts
              CROSS JOIN travel_schedule their_ts
              WHERE my_ts.user_id = p_user_id
                AND their_ts.user_id = p.id
                AND my_ts.latitude IS NOT NULL
                AND my_ts.longitude IS NOT NULL
                AND their_ts.latitude IS NOT NULL
                AND their_ts.longitude IS NOT NULL
                AND (
                    3959.0 * 2 * ASIN(SQRT(
                        POWER(SIN(RADIANS(their_ts.latitude - my_ts.latitude) / 2), 2) +
                        COS(RADIANS(my_ts.latitude)) * COS(RADIANS(their_ts.latitude)) *
                        POWER(SIN(RADIANS(their_ts.longitude - my_ts.longitude) / 2), 2)
                    ))
                ) <= p_max_distance_miles
          )
      )
    LIMIT p_limit;
$$;
