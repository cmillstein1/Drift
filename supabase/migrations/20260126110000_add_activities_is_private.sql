-- Add is_private to activities for share visibility
-- Private activities: only the creator can share. Public: anyone can share.
ALTER TABLE public.activities
ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_activities_is_private ON public.activities(is_private);
