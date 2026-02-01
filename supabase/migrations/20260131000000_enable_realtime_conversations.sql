-- Enable Realtime for conversations table so that when a new message is inserted,
-- the trigger updates conversations.updated_at and clients receive the UPDATE event.
-- This allows the Messages list and unread badge to update in real time.

-- Only add if not already a member (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'conversations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
    END IF;
END $$;
