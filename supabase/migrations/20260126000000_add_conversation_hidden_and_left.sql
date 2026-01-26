-- Add hidden_at and left_at to conversation_participants for hide/delete chat
-- hidden_at: when set, conversation appears in "Hidden" section (reversible)
-- left_at: when set, user has left/deleted the conversation (excluded from list)
--
-- WHERE TO SEE THESE IN SUPABASE:
-- Dashboard → Table Editor → select table "conversation_participants" (not "conversations").
-- The new columns are: hidden_at, left_at (both timestamp with time zone, nullable).

ALTER TABLE public.conversation_participants
ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

COMMENT ON COLUMN public.conversation_participants.hidden_at IS 'When set, conversation is in user''s Hidden list';
COMMENT ON COLUMN public.conversation_participants.left_at IS 'When set, user has left/deleted the conversation';
