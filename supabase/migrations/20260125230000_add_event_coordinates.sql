-- ============================================
-- Add latitude/longitude to community_posts for events
-- ============================================

-- Add coordinate columns
ALTER TABLE community_posts
ADD COLUMN IF NOT EXISTS event_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS event_longitude DOUBLE PRECISION;

-- Create index for geo queries
CREATE INDEX IF NOT EXISTS idx_community_posts_coordinates
    ON community_posts(event_latitude, event_longitude)
    WHERE type = 'event' AND event_latitude IS NOT NULL AND event_longitude IS NOT NULL;
