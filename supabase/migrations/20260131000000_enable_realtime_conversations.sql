-- Enable Realtime for conversations table so that when a new message is inserted,
-- the trigger updates conversations.updated_at and clients receive the UPDATE event.
-- This allows the Messages list and unread badge to update in real time.
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
