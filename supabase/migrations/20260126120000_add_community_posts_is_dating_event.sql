-- Add is_dating_event to community_posts (events only)
-- When true, only users with dating or both (not friends-only) see the event.
ALTER TABLE public.community_posts
ADD COLUMN IF NOT EXISTS is_dating_event BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.community_posts.is_dating_event IS 'If true, event is only visible to users with dating or both (hidden from friends-only).';

CREATE INDEX IF NOT EXISTS idx_community_posts_is_dating_event
ON public.community_posts(is_dating_event) WHERE type = 'event';
