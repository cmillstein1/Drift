-- Create reports table for content/user reporting
-- Stores reports with content snapshots (preserved even if original is deleted)

CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,

    -- Content being reported (polymorphic - only one should be set, or none for profile-only reports)
    post_id UUID REFERENCES public.community_posts(id) ON DELETE SET NULL,
    message_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    activity_id UUID REFERENCES public.activities(id) ON DELETE SET NULL,

    -- Report details
    category TEXT NOT NULL CHECK (category IN ('spam', 'harassment', 'inappropriate', 'scam', 'other')),
    description TEXT,
    content_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_reports_status ON public.reports(status);
CREATE INDEX idx_reports_reporter ON public.reports(reporter_id);
CREATE INDEX idx_reports_reported_user ON public.reports(reported_user_id);
CREATE INDEX idx_reports_created_at ON public.reports(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports (insert only - no viewing, updating, or deleting their own reports)
CREATE POLICY "Authenticated users can create reports"
    ON public.reports
    FOR INSERT
    TO authenticated
    WITH CHECK (reporter_id = auth.uid());

-- Add comment for documentation
COMMENT ON TABLE public.reports IS 'User reports for content moderation. content_snapshot preserves reported content even if original is deleted.';
