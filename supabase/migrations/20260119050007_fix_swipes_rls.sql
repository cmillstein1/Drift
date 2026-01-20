-- Migration: Fix swipes RLS policy
-- Description: Allow users to see swipes where they are either the swiper OR the swiped
-- This enables the "Likes You" feature to work

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Users can only see their own swipes" ON public.swipes;

-- Create new policy that allows seeing swipes in both directions
CREATE POLICY "Users can see swipes involving them" ON public.swipes
    FOR SELECT USING (auth.uid() = swiper_id OR auth.uid() = swiped_id);
