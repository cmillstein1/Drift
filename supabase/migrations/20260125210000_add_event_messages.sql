-- ============================================
-- Add event group messages table
-- ============================================

-- Create event_messages table for group chat
CREATE TABLE IF NOT EXISTS event_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_event_messages_event_id
    ON event_messages(event_id);
CREATE INDEX IF NOT EXISTS idx_event_messages_created_at
    ON event_messages(event_id, created_at DESC);

-- Enable RLS
ALTER TABLE event_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only attendees can view messages
CREATE POLICY "Attendees can view event messages"
    ON event_messages FOR SELECT
    USING (
        -- User is the event author
        EXISTS (
            SELECT 1 FROM community_posts
            WHERE community_posts.id = event_messages.event_id
            AND community_posts.author_id = auth.uid()
        )
        -- Or user is a confirmed attendee
        OR EXISTS (
            SELECT 1 FROM event_attendees
            WHERE event_attendees.post_id = event_messages.event_id
            AND event_attendees.user_id = auth.uid()
            AND event_attendees.status = 'confirmed'
        )
    );

-- RLS Policy: Only attendees can send messages
CREATE POLICY "Attendees can send event messages"
    ON event_messages FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND (
            -- User is the event author
            EXISTS (
                SELECT 1 FROM community_posts
                WHERE community_posts.id = event_messages.event_id
                AND community_posts.author_id = auth.uid()
            )
            -- Or user is a confirmed attendee
            OR EXISTS (
                SELECT 1 FROM event_attendees
                WHERE event_attendees.post_id = event_messages.event_id
                AND event_attendees.user_id = auth.uid()
                AND event_attendees.status = 'confirmed'
            )
        )
    );

-- RLS Policy: Users can only delete their own messages
CREATE POLICY "Users can delete own messages"
    ON event_messages FOR DELETE
    USING (auth.uid() = user_id);
