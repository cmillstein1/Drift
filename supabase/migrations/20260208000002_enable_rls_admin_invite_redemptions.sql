-- Migration: Enable RLS on admin_invite_redemptions
-- Description: Secure admin_invite_redemptions table with row level security

ALTER TABLE public.admin_invite_redemptions ENABLE ROW LEVEL SECURITY;

-- Users can read their own redemption record
CREATE POLICY "Users can view own redemption"
    ON public.admin_invite_redemptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Only the edge function (service role) inserts rows, so no INSERT policy needed for authenticated users
