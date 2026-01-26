-- ============================================
-- Fix private event visibility
-- Private events should be visible in the feed, just with hidden details
-- The detail hiding is handled at the application level
-- ============================================

-- Drop the overly restrictive policy
DROP POLICY IF EXISTS "Anyone can view public posts or own posts" ON community_posts;

-- Create new policy that allows all non-deleted posts to be visible
-- Privacy (hiding location/attendees) is handled at the application level
CREATE POLICY "Anyone can view non-deleted posts"
    ON community_posts FOR SELECT
    USING (deleted_at IS NULL);
