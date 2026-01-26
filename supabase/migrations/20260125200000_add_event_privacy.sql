-- ============================================
-- Add event privacy field to community_posts
-- ============================================

-- Add event_privacy column
ALTER TABLE community_posts
ADD COLUMN IF NOT EXISTS event_privacy TEXT DEFAULT 'public'
CHECK (event_privacy IN ('public', 'private', 'invite_only') OR event_privacy IS NULL);

-- Create index for filtering by privacy
CREATE INDEX IF NOT EXISTS idx_community_posts_privacy
ON community_posts(event_privacy) WHERE type = 'event';

-- Update RLS policy for viewing posts to consider privacy
DROP POLICY IF EXISTS "Anyone can view non-deleted posts" ON community_posts;

CREATE POLICY "Anyone can view public posts or own posts"
    ON community_posts FOR SELECT
    USING (
        deleted_at IS NULL
        AND (
            -- Help posts are always visible
            type = 'help'
            -- Public events are visible to all
            OR (type = 'event' AND event_privacy = 'public')
            -- Private/invite-only events visible to author
            OR auth.uid() = author_id
            -- Private/invite-only events visible to confirmed attendees
            OR EXISTS (
                SELECT 1 FROM event_attendees
                WHERE event_attendees.post_id = community_posts.id
                AND event_attendees.user_id = auth.uid()
                AND event_attendees.status = 'confirmed'
            )
        )
    );
