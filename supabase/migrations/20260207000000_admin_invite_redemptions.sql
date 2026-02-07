-- Table for users who redeemed the universal admin invite code (multi-use code for judges, Apple review, etc.).
-- Redeem-invite edge function checks ADMIN_INVITE_CODE env; when it matches, we record here instead of consuming a normal invite.
-- To disable the admin code later, remove ADMIN_INVITE_CODE from the edge function env; existing rows can stay so users keep access.
CREATE TABLE IF NOT EXISTS public.admin_invite_redemptions (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  redeemed_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.admin_invite_redemptions IS 'Users who used the universal admin invite code; allows multi-use code without touching invitations table.';
