-- Migration: Create conversation function
-- Description: Use SECURITY DEFINER function to create conversations

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
BEGIN
    -- Create the conversation
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_conversation_with_participants TO authenticated;
