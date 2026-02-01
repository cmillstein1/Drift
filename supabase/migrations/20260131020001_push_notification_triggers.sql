-- Migration: Push Notification Triggers
-- Description: Database triggers to send push notifications via Edge Functions
-- Uses pg_net extension to make HTTP calls to the send-push Edge Function

-- Note: pg_net is pre-enabled on Supabase hosted instances
-- For local development, ensure it's enabled in supabase/config.toml

-- ============================================
-- Helper function to call send-push Edge Function
-- ============================================
CREATE OR REPLACE FUNCTION send_push_notification(
    target_user_id UUID,
    notification_title TEXT,
    notification_body TEXT,
    notification_category TEXT,
    notification_data JSONB DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
    edge_function_url TEXT;
    service_role_key TEXT;
    request_id BIGINT;
BEGIN
    -- Build the Edge Function URL using Supabase project URL
    -- This uses the SUPABASE_URL environment variable set in the database
    edge_function_url := 'https://' || current_setting('request.headers', true)::json->>'host' || '/functions/v1/send-push';

    -- For production, use the project URL directly
    -- You'll need to set this via: ALTER DATABASE postgres SET app.supabase_url = 'https://your-project.supabase.co';
    IF edge_function_url IS NULL OR edge_function_url = 'https:///functions/v1/send-push' THEN
        edge_function_url := current_setting('app.supabase_url', true) || '/functions/v1/send-push';
    END IF;

    service_role_key := current_setting('app.service_role_key', true);

    -- Skip if settings not configured
    IF edge_function_url IS NULL OR service_role_key IS NULL THEN
        RAISE WARNING 'Push notification settings not configured. Set app.supabase_url and app.service_role_key';
        RETURN;
    END IF;

    -- Make async HTTP request to Edge Function using pg_net
    SELECT net.http_post(
        url := edge_function_url,
        body := jsonb_build_object(
            'user_id', target_user_id::text,
            'title', notification_title,
            'body', notification_body,
            'category', notification_category,
            'data', notification_data
        ),
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || service_role_key
        )
    ) INTO request_id;

EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the transaction
    RAISE WARNING 'Failed to send push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 1. New Message Notification Trigger
-- ============================================
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    participant RECORD;
    sender_name TEXT;
    message_preview TEXT;
BEGIN
    -- Get sender's name
    SELECT name INTO sender_name FROM profiles WHERE id = NEW.sender_id;
    sender_name := COALESCE(sender_name, 'Someone');

    -- Truncate message for preview
    message_preview := LEFT(NEW.content, 100);
    IF LENGTH(NEW.content) > 100 THEN
        message_preview := message_preview || '...';
    END IF;

    -- Notify all participants except the sender
    FOR participant IN
        SELECT user_id
        FROM conversation_participants
        WHERE conversation_id = NEW.conversation_id
        AND user_id != NEW.sender_id
    LOOP
        PERFORM send_push_notification(
            participant.user_id,
            sender_name,
            message_preview,
            'newMessages',
            jsonb_build_object(
                'conversation_id', NEW.conversation_id::text,
                'message_id', NEW.id::text,
                'type', 'message'
            )
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    WHEN (NEW.deleted_at IS NULL)
    EXECUTE FUNCTION notify_new_message();

-- ============================================
-- 2. New Match Notification Trigger
-- ============================================
CREATE OR REPLACE FUNCTION notify_new_match()
RETURNS TRIGGER AS $$
DECLARE
    user1_name TEXT;
    user2_name TEXT;
BEGIN
    -- Only send notification when match is first created (is_match becomes true)
    IF NEW.is_match = TRUE AND (OLD IS NULL OR OLD.is_match = FALSE) THEN
        -- Get both users' names
        SELECT name INTO user1_name FROM profiles WHERE id = NEW.user1_id;
        SELECT name INTO user2_name FROM profiles WHERE id = NEW.user2_id;

        user1_name := COALESCE(user1_name, 'Someone');
        user2_name := COALESCE(user2_name, 'Someone');

        -- Notify user1
        PERFORM send_push_notification(
            NEW.user1_id,
            'New Match!',
            'You matched with ' || user2_name || '!',
            'newMatches',
            jsonb_build_object(
                'match_id', NEW.id::text,
                'matched_user_id', NEW.user2_id::text,
                'type', 'match'
            )
        );

        -- Notify user2
        PERFORM send_push_notification(
            NEW.user2_id,
            'New Match!',
            'You matched with ' || user1_name || '!',
            'newMatches',
            jsonb_build_object(
                'match_id', NEW.id::text,
                'matched_user_id', NEW.user1_id::text,
                'type', 'match'
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_match
    AFTER INSERT OR UPDATE OF is_match ON matches
    FOR EACH ROW
    WHEN (NEW.is_match = TRUE)
    EXECUTE FUNCTION notify_new_match();

-- ============================================
-- 3. Event Attendee Join Notification Trigger
-- ============================================
CREATE OR REPLACE FUNCTION notify_event_attendee()
RETURNS TRIGGER AS $$
DECLARE
    event_author_id UUID;
    event_title TEXT;
    attendee_name TEXT;
BEGIN
    -- Only notify on new confirmed attendance (not updates)
    IF TG_OP = 'INSERT' AND NEW.status = 'confirmed' THEN
        -- Get event info
        SELECT author_id, title INTO event_author_id, event_title
        FROM community_posts
        WHERE id = NEW.post_id AND type = 'event';

        -- Don't notify if author joins their own event
        IF event_author_id IS NOT NULL AND event_author_id != NEW.user_id THEN
            -- Get attendee name
            SELECT name INTO attendee_name FROM profiles WHERE id = NEW.user_id;
            attendee_name := COALESCE(attendee_name, 'Someone');

            PERFORM send_push_notification(
                event_author_id,
                'New Attendee',
                attendee_name || ' is joining "' || LEFT(event_title, 50) || '"',
                'eventUpdates',
                jsonb_build_object(
                    'post_id', NEW.post_id::text,
                    'attendee_id', NEW.user_id::text,
                    'type', 'event_join'
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_event_attendee
    AFTER INSERT ON event_attendees
    FOR EACH ROW
    EXECUTE FUNCTION notify_event_attendee();

-- ============================================
-- 4. Post Reply Notification Trigger
-- ============================================
CREATE OR REPLACE FUNCTION notify_post_reply()
RETURNS TRIGGER AS $$
DECLARE
    post_author_id UUID;
    post_title TEXT;
    post_type TEXT;
    replier_name TEXT;
    reply_preview TEXT;
BEGIN
    -- Get post info
    SELECT author_id, title, type INTO post_author_id, post_title, post_type
    FROM community_posts
    WHERE id = NEW.post_id;

    -- Don't notify if author replies to their own post
    IF post_author_id IS NOT NULL AND post_author_id != NEW.author_id THEN
        -- Get replier name
        SELECT name INTO replier_name FROM profiles WHERE id = NEW.author_id;
        replier_name := COALESCE(replier_name, 'Someone');

        -- Truncate reply for preview
        reply_preview := LEFT(NEW.content, 80);
        IF LENGTH(NEW.content) > 80 THEN
            reply_preview := reply_preview || '...';
        END IF;

        PERFORM send_push_notification(
            post_author_id,
            replier_name || ' replied',
            reply_preview,
            'eventUpdates',  -- Using eventUpdates category for community activity
            jsonb_build_object(
                'post_id', NEW.post_id::text,
                'reply_id', NEW.id::text,
                'post_type', post_type,
                'type', 'reply'
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_post_reply
    AFTER INSERT ON post_replies
    FOR EACH ROW
    WHEN (NEW.deleted_at IS NULL)
    EXECUTE FUNCTION notify_post_reply();

-- ============================================
-- Documentation
-- ============================================
COMMENT ON FUNCTION send_push_notification IS 'Helper function to send push notifications via Edge Function';
COMMENT ON FUNCTION notify_new_message IS 'Trigger function to notify conversation participants of new messages';
COMMENT ON FUNCTION notify_new_match IS 'Trigger function to notify both users when a dating match occurs';
COMMENT ON FUNCTION notify_event_attendee IS 'Trigger function to notify event hosts when someone joins';
COMMENT ON FUNCTION notify_post_reply IS 'Trigger function to notify post authors of new replies';
