-- Migration: Fix Conversations Insert Policy v2
-- Description: Simpler RLS policies for conversations

-- Drop all existing INSERT policies on conversations
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;

-- Simple INSERT policy - any authenticated user can create conversations
CREATE POLICY "Authenticated users can create conversations" ON public.conversations
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);

-- Fix conversation_participants INSERT policies
DROP POLICY IF EXISTS "Users can add themselves as participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can add participants to conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Conversation members can add other participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can add participants" ON public.conversation_participants;

-- Simple INSERT policy - any authenticated user can add participants
CREATE POLICY "Authenticated users can add participants" ON public.conversation_participants
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);
