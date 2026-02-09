-- Migration: Friend Request Push Notification Trigger
-- Description: Sends a push notification to the addressee when a friend request is created

CREATE OR REPLACE FUNCTION notify_new_friend_request()
RETURNS TRIGGER AS $$
DECLARE
    requester_name TEXT;
BEGIN
    -- Only notify on new pending friend requests
    IF NEW.status = 'pending' THEN
        -- Get requester's name
        SELECT name INTO requester_name FROM profiles WHERE id = NEW.requester_id;
        requester_name := COALESCE(requester_name, 'Someone');

        PERFORM send_push_notification(
            NEW.addressee_id,
            'Friend Request',
            requester_name || ' sent you a friend request',
            'friendRequests',
            jsonb_build_object(
                'friend_id', NEW.id::text,
                'requester_id', NEW.requester_id::text,
                'type', 'friend_request'
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_friend_request
    AFTER INSERT ON friends
    FOR EACH ROW
    WHEN (NEW.status = 'pending')
    EXECUTE FUNCTION notify_new_friend_request();

COMMENT ON FUNCTION notify_new_friend_request IS 'Trigger function to notify users of incoming friend requests';
