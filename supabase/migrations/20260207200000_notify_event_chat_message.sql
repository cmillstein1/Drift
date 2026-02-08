-- Migration: Event Chat Message Notification Trigger
-- Description: Notifies event poster when someone sends a message in their event group chat

-- ============================================
-- Event Chat Message Notification Trigger
-- ============================================
CREATE OR REPLACE FUNCTION notify_event_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    event_author_id UUID;
    sender_name TEXT;
    message_preview TEXT;
BEGIN
    -- Get event author
    SELECT author_id INTO event_author_id
    FROM community_posts
    WHERE id = NEW.event_id;

    -- Don't notify if sender is the event author
    IF event_author_id IS NOT NULL AND event_author_id != NEW.user_id THEN
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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_event_chat_message
    AFTER INSERT ON event_messages
    FOR EACH ROW
    EXECUTE FUNCTION notify_event_chat_message();

COMMENT ON FUNCTION notify_event_chat_message IS 'Trigger function to notify event hosts when someone sends a group chat message';
