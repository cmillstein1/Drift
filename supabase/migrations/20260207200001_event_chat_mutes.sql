-- Migration: Event Chat Mutes
-- Description: Table for muting event group chat notifications per user.
-- The notify_event_chat_message trigger checks this table before sending.

-- ============================================
-- Event Chat Mutes table
-- ============================================
CREATE TABLE IF NOT EXISTS event_chat_mutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_chat_mutes_lookup
    ON event_chat_mutes(event_id, user_id);

-- Enable RLS
ALTER TABLE event_chat_mutes ENABLE ROW LEVEL SECURITY;

-- Users can view their own mutes
CREATE POLICY "Users can view own mutes"
    ON event_chat_mutes FOR SELECT
    USING (auth.uid() = user_id);

-- Users can mute chats
CREATE POLICY "Users can mute chats"
    ON event_chat_mutes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can unmute chats
CREATE POLICY "Users can unmute chats"
    ON event_chat_mutes FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- Update trigger to respect mutes
-- ============================================
CREATE OR REPLACE FUNCTION notify_event_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    event_author_id UUID;
    sender_name TEXT;
    message_preview TEXT;
    is_muted BOOLEAN;
BEGIN
    -- Get event author
    SELECT author_id INTO event_author_id
    FROM community_posts
    WHERE id = NEW.event_id;

    -- Don't notify if sender is the event author
    IF event_author_id IS NOT NULL AND event_author_id != NEW.user_id THEN
        -- Check if event author has muted this chat
        SELECT EXISTS(
            SELECT 1 FROM event_chat_mutes
            WHERE event_id = NEW.event_id AND user_id = event_author_id
        ) INTO is_muted;

        IF NOT is_muted THEN
            -- Get sender name
            SELECT name INTO sender_name FROM profiles WHERE id = NEW.user_id;
            sender_name := COALESCE(sender_name, 'Someone');

            -- Truncate message for preview
            message_preview := LEFT(NEW.content, 100);
            IF LENGTH(NEW.content) > 100 THEN
                message_preview := message_preview || '...';
            END IF;

            PERFORM send_push_notification(
                event_author_id,
                sender_name,
                message_preview,
                'eventUpdates',
                jsonb_build_object(
                    'post_id', NEW.event_id::text,
                    'message_id', NEW.id::text,
                    'type', 'event_chat'
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
