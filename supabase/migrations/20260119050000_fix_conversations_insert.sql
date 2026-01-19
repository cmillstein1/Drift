-- Migration: Fix Conversations Insert Policy
-- Description: Ensure users can create conversations

-- Drop existing INSERT policy if it exists
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;

-- Recreate INSERT policy - authenticated users can create conversations
CREATE POLICY "Users can create conversations" ON public.conversations
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);

-- Also ensure the conversation_participants INSERT works properly
-- Users should be able to add themselves and other users to a conversation they just created
DROP POLICY IF EXISTS "Users can add themselves as participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can add participants to conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Conversation members can add other participants" ON public.conversation_participants;

-- Simple policy: authenticated users can add participants
CREATE POLICY "Users can add participants" ON public.conversation_participants
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);
