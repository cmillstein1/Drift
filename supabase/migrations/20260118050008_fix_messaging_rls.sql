-- Migration: Fix Messaging RLS Infinite Recursion
-- Description: Fix the infinite recursion in conversation_participants policy

-- Drop the problematic policies
DROP POLICY IF EXISTS "Users can view participants of their conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Conversation members can add other participants" ON public.conversation_participants;

-- Create a helper function that bypasses RLS to check membership
CREATE OR REPLACE FUNCTION public.is_conversation_member(conv_id UUID, uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = conv_id AND user_id = uid
    );
$$;

-- Recreate the view participants policy using the helper function
CREATE POLICY "Users can view participants of their conversations" ON public.conversation_participants
    FOR SELECT USING (
        user_id = auth.uid() OR
        public.is_conversation_member(conversation_id, auth.uid())
    );

-- Recreate the add participants policy using the helper function
CREATE POLICY "Conversation members can add other participants" ON public.conversation_participants
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR
        public.is_conversation_member(conversation_id, auth.uid())
    );

-- Also fix conversations policy to use the helper
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON public.conversations;

CREATE POLICY "Users can view their conversations" ON public.conversations
    FOR SELECT USING (
        public.is_conversation_member(id, auth.uid())
    );

CREATE POLICY "Users can update their conversations" ON public.conversations
    FOR UPDATE USING (
        public.is_conversation_member(id, auth.uid())
    );

-- Fix messages policies too
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON public.messages;

CREATE POLICY "Users can view messages in their conversations" ON public.messages
    FOR SELECT USING (
        public.is_conversation_member(conversation_id, auth.uid())
        AND deleted_at IS NULL
    );

CREATE POLICY "Users can send messages to their conversations" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        public.is_conversation_member(conversation_id, auth.uid())
    );
