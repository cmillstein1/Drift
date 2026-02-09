-- Migration: Fix Function Search Paths
-- Description: Set search_path = '' on all public functions to resolve security linter warnings

-- 1. handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 2. update_updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- 3. update_community_updated_at
CREATE OR REPLACE FUNCTION public.update_community_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- 4. check_mutual_match
CREATE OR REPLACE FUNCTION public.check_mutual_match()
RETURNS TRIGGER AS $$
DECLARE
    other_swipe RECORD;
BEGIN
    IF NEW.direction = 'right' THEN
        SELECT * INTO other_swipe FROM public.swipes
        WHERE swiper_id = NEW.swiped_id
        AND swiped_id = NEW.swiper_id
        AND direction = 'right';

        IF FOUND THEN
            INSERT INTO public.matches (user1_id, user2_id, matched_at, is_match)
            VALUES (
                LEAST(NEW.swiper_id, NEW.swiped_id),
                GREATEST(NEW.swiper_id, NEW.swiped_id),
                NOW(),
                TRUE
            )
            ON CONFLICT (user1_id, user2_id)
            DO UPDATE SET matched_at = NOW(), is_match = TRUE;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 5. update_conversation_timestamp
CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 6. update_attendee_count
CREATE OR REPLACE FUNCTION public.update_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.activities
        SET current_attendees = current_attendees + 1
        WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.activities
        SET current_attendees = current_attendees - 1
        WHERE id = OLD.activity_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 7. update_channel_member_count
CREATE OR REPLACE FUNCTION public.update_channel_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.van_builder_channels
        SET member_count = member_count + 1
        WHERE id = NEW.channel_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.van_builder_channels
        SET member_count = member_count - 1
        WHERE id = OLD.channel_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 8. update_reply_count
CREATE OR REPLACE FUNCTION public.update_reply_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
        UPDATE public.channel_messages
        SET reply_count = reply_count + 1
        WHERE id = NEW.parent_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 9. update_post_like_count
CREATE OR REPLACE FUNCTION public.update_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.post_id IS NOT NULL THEN
            UPDATE public.community_posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
        ELSIF NEW.reply_id IS NOT NULL THEN
            UPDATE public.post_replies SET like_count = like_count + 1 WHERE id = NEW.reply_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.post_id IS NOT NULL THEN
            UPDATE public.community_posts SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.post_id;
        ELSIF OLD.reply_id IS NOT NULL THEN
            UPDATE public.post_replies SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.reply_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- 10. update_post_reply_count
CREATE OR REPLACE FUNCTION public.update_post_reply_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.community_posts SET reply_count = reply_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.community_posts SET reply_count = GREATEST(0, reply_count - 1) WHERE id = OLD.post_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
            UPDATE public.community_posts SET reply_count = GREATEST(0, reply_count - 1) WHERE id = NEW.post_id;
        ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
            UPDATE public.community_posts SET reply_count = reply_count + 1 WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- 11. update_event_attendee_count
CREATE OR REPLACE FUNCTION public.update_event_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'confirmed' THEN
            UPDATE public.community_posts SET current_attendees = current_attendees + 1 WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status = 'confirmed' THEN
            UPDATE public.community_posts SET current_attendees = GREATEST(0, current_attendees - 1) WHERE id = OLD.post_id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
            UPDATE public.community_posts SET current_attendees = current_attendees + 1 WHERE id = NEW.post_id;
        ELSIF OLD.status = 'confirmed' AND NEW.status != 'confirmed' THEN
            UPDATE public.community_posts SET current_attendees = GREATEST(0, current_attendees - 1) WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- 12. notify_new_message
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    participant RECORD;
    sender_name TEXT;
    message_preview TEXT;
BEGIN
    SELECT name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    sender_name := COALESCE(sender_name, 'Someone');

    message_preview := LEFT(NEW.content, 100);
    IF LENGTH(NEW.content) > 100 THEN
        message_preview := message_preview || '...';
    END IF;

    FOR participant IN
        SELECT user_id
        FROM public.conversation_participants
        WHERE conversation_id = NEW.conversation_id
        AND user_id != NEW.sender_id
    LOOP
        PERFORM public.send_push_notification(
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 13. notify_new_match
CREATE OR REPLACE FUNCTION public.notify_new_match()
RETURNS TRIGGER AS $$
DECLARE
    user1_name TEXT;
    user2_name TEXT;
BEGIN
    IF NEW.is_match = TRUE AND (OLD IS NULL OR OLD.is_match = FALSE) THEN
        SELECT name INTO user1_name FROM public.profiles WHERE id = NEW.user1_id;
        SELECT name INTO user2_name FROM public.profiles WHERE id = NEW.user2_id;

        user1_name := COALESCE(user1_name, 'Someone');
        user2_name := COALESCE(user2_name, 'Someone');

        PERFORM public.send_push_notification(
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

        PERFORM public.send_push_notification(
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 14. notify_event_attendee
CREATE OR REPLACE FUNCTION public.notify_event_attendee()
RETURNS TRIGGER AS $$
DECLARE
    event_author_id UUID;
    event_title TEXT;
    attendee_name TEXT;
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'confirmed' THEN
        SELECT author_id, title INTO event_author_id, event_title
        FROM public.community_posts
        WHERE id = NEW.post_id AND type = 'event';

        IF event_author_id IS NOT NULL AND event_author_id != NEW.user_id THEN
            SELECT name INTO attendee_name FROM public.profiles WHERE id = NEW.user_id;
            attendee_name := COALESCE(attendee_name, 'Someone');

            PERFORM public.send_push_notification(
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 15. notify_post_reply
CREATE OR REPLACE FUNCTION public.notify_post_reply()
RETURNS TRIGGER AS $$
DECLARE
    post_author_id UUID;
    post_title TEXT;
    post_type TEXT;
    replier_name TEXT;
    reply_preview TEXT;
BEGIN
    SELECT author_id, title, type INTO post_author_id, post_title, post_type
    FROM public.community_posts
    WHERE id = NEW.post_id;

    IF post_author_id IS NOT NULL AND post_author_id != NEW.author_id THEN
        SELECT name INTO replier_name FROM public.profiles WHERE id = NEW.author_id;
        replier_name := COALESCE(replier_name, 'Someone');

        reply_preview := LEFT(NEW.content, 80);
        IF LENGTH(NEW.content) > 80 THEN
            reply_preview := reply_preview || '...';
        END IF;

        PERFORM public.send_push_notification(
            post_author_id,
            replier_name || ' replied',
            reply_preview,
            'eventUpdates',
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 16. send_push_notification
CREATE OR REPLACE FUNCTION public.send_push_notification(
    target_user_id UUID,
    notification_title TEXT,
    notification_body TEXT,
    notification_category TEXT,
    notification_data JSONB DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
    edge_function_url TEXT := 'https://kbedevzqiqhkleokehhv.supabase.co/functions/v1/send-push';
    service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtiZWRldnpxaXFoa2xlb2tlaGh2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODQ5NTYzOCwiZXhwIjoyMDg0MDcxNjM4fQ.3MUWFGv5nOdx3RO1sH_RjpwSr5nxwyz3b2KoXlGEb8E';
    request_id BIGINT;
BEGIN
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
    RAISE WARNING 'Failed to send push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- 17. notify_event_chat_message
CREATE OR REPLACE FUNCTION public.notify_event_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    event_author_id UUID;
    sender_name TEXT;
    message_preview TEXT;
    is_muted BOOLEAN;
BEGIN
    SELECT author_id INTO event_author_id
    FROM public.community_posts
    WHERE id = NEW.event_id;

    IF event_author_id IS NOT NULL AND event_author_id != NEW.user_id THEN
        SELECT EXISTS(
            SELECT 1 FROM public.event_chat_mutes
            WHERE event_id = NEW.event_id AND user_id = event_author_id
        ) INTO is_muted;

        IF NOT is_muted THEN
            SELECT name INTO sender_name FROM public.profiles WHERE id = NEW.user_id;
            sender_name := COALESCE(sender_name, 'Someone');

            message_preview := LEFT(NEW.content, 100);
            IF LENGTH(NEW.content) > 100 THEN
                message_preview := message_preview || '...';
            END IF;

            PERFORM public.send_push_notification(
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
