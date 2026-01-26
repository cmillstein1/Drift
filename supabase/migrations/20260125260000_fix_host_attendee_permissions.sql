-- ============================================
-- Fix RLS policies for event_attendees
-- Allow event hosts to approve/deny join requests
-- ============================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can update their own attendance" ON event_attendees;
DROP POLICY IF EXISTS "Users can leave events" ON event_attendees;

-- Users can update their own attendance
CREATE POLICY "Users can update their own attendance"
    ON event_attendees FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Event hosts can update any attendee record for their events (approve/deny requests)
CREATE POLICY "Hosts can update attendees for their events"
    ON event_attendees FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM community_posts
            WHERE community_posts.id = event_attendees.post_id
            AND community_posts.author_id = auth.uid()
        )
    );

-- Users can delete their own attendance (leave event)
CREATE POLICY "Users can leave events"
    ON event_attendees FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Event hosts can delete any attendee record for their events (remove/deny)
CREATE POLICY "Hosts can remove attendees from their events"
    ON event_attendees FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM community_posts
            WHERE community_posts.id = event_attendees.post_id
            AND community_posts.author_id = auth.uid()
        )
    );
