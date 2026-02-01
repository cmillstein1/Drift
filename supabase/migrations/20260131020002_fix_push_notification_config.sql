-- Migration: Fix Push Notification Config
-- Description: Hardcode Edge Function URL and service role key in the trigger function
-- (Supabase hosted doesn't allow ALTER DATABASE SET for custom parameters)

-- Update the helper function with hardcoded config
CREATE OR REPLACE FUNCTION send_push_notification(
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
