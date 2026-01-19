-- Migration: Fix conversation deduplication
-- Description: Update function to find existing conversations before creating new ones

-- Clear mock messages and conversations to start fresh
DELETE FROM public.messages;
DELETE FROM public.conversation_participants;
DELETE FROM public.conversations;

-- Update the function to check for existing conversation first
CREATE OR REPLACE FUNCTION public.create_conversation_with_participants(
    p_type conversation_type,
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_conversation_id UUID;
    v_existing_id UUID;
BEGIN
    -- First, check if a conversation already exists between these two users
    SELECT c.id INTO v_existing_id
    FROM conversations c
    WHERE c.type = p_type
    AND EXISTS (
        SELECT 1 FROM conversation_participants cp1
        WHERE cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM conversation_participants cp2
        WHERE cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
    )
    LIMIT 1;

    -- If found, return the existing conversation
    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- Otherwise, create a new conversation
    INSERT INTO conversations (type)
    VALUES (p_type)
    RETURNING id INTO v_conversation_id;

    -- Add both participants
    INSERT INTO conversation_participants (conversation_id, user_id)
    VALUES
        (v_conversation_id, p_user1_id),
        (v_conversation_id, p_user2_id);

    RETURN v_conversation_id;
END;
$$;
