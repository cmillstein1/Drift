-- Migration: Fix messages RLS and clear mock data
-- Description: Ensure messages can be sent and received

-- Clear any remaining mock messages
DELETE FROM public.messages;

-- Drop existing messages policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- Simpler SELECT policy - users can see messages in conversations they're part of
CREATE POLICY "Users can view messages" ON public.messages
    FOR SELECT
    TO authenticated
    USING (
        public.is_conversation_member(conversation_id, auth.uid())
    );

-- Simpler INSERT policy - users can send messages to conversations they're part of
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid() AND
        public.is_conversation_member(conversation_id, auth.uid())
    );

-- UPDATE policy
CREATE POLICY "Users can update own messages" ON public.messages
    FOR UPDATE
    TO authenticated
    USING (sender_id = auth.uid());
