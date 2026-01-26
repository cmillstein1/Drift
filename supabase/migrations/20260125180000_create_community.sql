-- ============================================
-- Community Posts Migration
-- Creates tables for unified community feed (Events + Help posts)
-- ============================================

-- Enable RLS on all tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;

-- ============================================
-- 1. community_posts - Main unified posts table
-- ============================================
CREATE TABLE IF NOT EXISTS community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Post type discriminator
    type TEXT NOT NULL CHECK (type IN ('event', 'help')),

    -- Common fields (both types)
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',

    -- Engagement counters (denormalized for performance)
    like_count INT DEFAULT 0,
    reply_count INT DEFAULT 0,

    -- Event-specific fields (NULL for help posts)
    event_datetime TIMESTAMPTZ,
    event_location TEXT,
    event_exact_location TEXT,  -- Revealed after joining
    max_attendees INT,
    current_attendees INT DEFAULT 0,

    -- Help-specific fields (NULL for event posts)
    help_category TEXT CHECK (help_category IN ('electrical', 'solar', 'plumbing', 'woodwork', 'mechanical', 'other') OR help_category IS NULL),
    is_solved BOOLEAN DEFAULT FALSE,
    best_answer_id UUID,  -- References post_replies(id), added as FK after post_replies is created

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- Soft delete
);

-- Indexes for community_posts
CREATE INDEX idx_community_posts_type ON community_posts(type);
CREATE INDEX idx_community_posts_author ON community_posts(author_id);
CREATE INDEX idx_community_posts_created ON community_posts(created_at DESC);
CREATE INDEX idx_community_posts_event_datetime ON community_posts(event_datetime) WHERE type = 'event';
CREATE INDEX idx_community_posts_help_category ON community_posts(help_category) WHERE type = 'help';
CREATE INDEX idx_community_posts_active ON community_posts(created_at DESC) WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for community_posts
CREATE POLICY "Anyone can view non-deleted posts"
    ON community_posts FOR SELECT
    USING (deleted_at IS NULL);

CREATE POLICY "Authenticated users can create posts"
    ON community_posts FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update their own posts"
    ON community_posts FOR UPDATE
    TO authenticated
    USING (auth.uid() = author_id);

CREATE POLICY "Authors can soft delete their own posts"
    ON community_posts FOR DELETE
    TO authenticated
    USING (auth.uid() = author_id);

-- ============================================
-- 2. post_replies - Comments/answers table
-- ============================================
CREATE TABLE IF NOT EXISTS post_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    content TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',
    parent_reply_id UUID REFERENCES post_replies(id) ON DELETE CASCADE,  -- Threading support

    like_count INT DEFAULT 0,
    is_expert_reply BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT no_self_reference CHECK (id != parent_reply_id)
);

-- Indexes for post_replies
CREATE INDEX idx_post_replies_post ON post_replies(post_id);
CREATE INDEX idx_post_replies_parent ON post_replies(parent_reply_id);
CREATE INDEX idx_post_replies_author ON post_replies(author_id);
CREATE INDEX idx_post_replies_active ON post_replies(post_id, created_at) WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE post_replies ENABLE ROW LEVEL SECURITY;

-- RLS Policies for post_replies
CREATE POLICY "Anyone can view non-deleted replies"
    ON post_replies FOR SELECT
    USING (deleted_at IS NULL);

CREATE POLICY "Authenticated users can create replies"
    ON post_replies FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update their own replies"
    ON post_replies FOR UPDATE
    TO authenticated
    USING (auth.uid() = author_id);

CREATE POLICY "Authors can delete their own replies"
    ON post_replies FOR DELETE
    TO authenticated
    USING (auth.uid() = author_id);

-- Add foreign key for best_answer_id now that post_replies exists
ALTER TABLE community_posts
    ADD CONSTRAINT fk_best_answer
    FOREIGN KEY (best_answer_id)
    REFERENCES post_replies(id)
    ON DELETE SET NULL;

-- ============================================
-- 3. post_likes - Engagement tracking table
-- ============================================
CREATE TABLE IF NOT EXISTS post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Polymorphic reference (one must be set)
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
    reply_id UUID REFERENCES post_replies(id) ON DELETE CASCADE,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT like_target_check CHECK (
        (post_id IS NOT NULL AND reply_id IS NULL) OR
        (post_id IS NULL AND reply_id IS NOT NULL)
    )
);

-- Unique constraints (partial indexes for nullable columns)
CREATE UNIQUE INDEX idx_unique_post_like ON post_likes(user_id, post_id) WHERE post_id IS NOT NULL;
CREATE UNIQUE INDEX idx_unique_reply_like ON post_likes(user_id, reply_id) WHERE reply_id IS NOT NULL;

-- Indexes for post_likes
CREATE INDEX idx_post_likes_post ON post_likes(post_id) WHERE post_id IS NOT NULL;
CREATE INDEX idx_post_likes_reply ON post_likes(reply_id) WHERE reply_id IS NOT NULL;
CREATE INDEX idx_post_likes_user ON post_likes(user_id);

-- Enable RLS
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for post_likes
CREATE POLICY "Anyone can view likes"
    ON post_likes FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can like"
    ON post_likes FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes"
    ON post_likes FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================
-- 4. event_attendees - Event participation table
-- ============================================
CREATE TABLE IF NOT EXISTS event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'cancelled')),

    joined_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_event_attendee UNIQUE (post_id, user_id)
);

-- Indexes for event_attendees
CREATE INDEX idx_event_attendees_post ON event_attendees(post_id);
CREATE INDEX idx_event_attendees_user ON event_attendees(user_id);
CREATE INDEX idx_event_attendees_status ON event_attendees(post_id, status) WHERE status = 'confirmed';

-- Enable RLS
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;

-- RLS Policies for event_attendees
CREATE POLICY "Anyone can view event attendees"
    ON event_attendees FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can join events"
    ON event_attendees FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own attendance"
    ON event_attendees FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can leave events"
    ON event_attendees FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================
-- 5. Triggers
-- ============================================

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_community_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_community_posts_updated_at
    BEFORE UPDATE ON community_posts
    FOR EACH ROW EXECUTE FUNCTION update_community_updated_at();

CREATE TRIGGER trigger_post_replies_updated_at
    BEFORE UPDATE ON post_replies
    FOR EACH ROW EXECUTE FUNCTION update_community_updated_at();

CREATE TRIGGER trigger_event_attendees_updated_at
    BEFORE UPDATE ON event_attendees
    FOR EACH ROW EXECUTE FUNCTION update_community_updated_at();

-- Trigger: Update like_count on community_posts
CREATE OR REPLACE FUNCTION update_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.post_id IS NOT NULL THEN
            UPDATE community_posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
        ELSIF NEW.reply_id IS NOT NULL THEN
            UPDATE post_replies SET like_count = like_count + 1 WHERE id = NEW.reply_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.post_id IS NOT NULL THEN
            UPDATE community_posts SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.post_id;
        ELSIF OLD.reply_id IS NOT NULL THEN
            UPDATE post_replies SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.reply_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_like_count
    AFTER INSERT OR DELETE ON post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_like_count();

-- Trigger: Update reply_count on community_posts
CREATE OR REPLACE FUNCTION update_post_reply_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET reply_count = reply_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET reply_count = GREATEST(0, reply_count - 1) WHERE id = OLD.post_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle soft delete
        IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
            UPDATE community_posts SET reply_count = GREATEST(0, reply_count - 1) WHERE id = NEW.post_id;
        ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
            UPDATE community_posts SET reply_count = reply_count + 1 WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reply_count
    AFTER INSERT OR DELETE OR UPDATE OF deleted_at ON post_replies
    FOR EACH ROW EXECUTE FUNCTION update_post_reply_count();

-- Trigger: Update current_attendees on community_posts
CREATE OR REPLACE FUNCTION update_event_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'confirmed' THEN
            UPDATE community_posts SET current_attendees = current_attendees + 1 WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status = 'confirmed' THEN
            UPDATE community_posts SET current_attendees = GREATEST(0, current_attendees - 1) WHERE id = OLD.post_id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
            UPDATE community_posts SET current_attendees = current_attendees + 1 WHERE id = NEW.post_id;
        ELSIF OLD.status = 'confirmed' AND NEW.status != 'confirmed' THEN
            UPDATE community_posts SET current_attendees = GREATEST(0, current_attendees - 1) WHERE id = NEW.post_id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_attendee_count
    AFTER INSERT OR DELETE OR UPDATE OF status ON event_attendees
    FOR EACH ROW EXECUTE FUNCTION update_event_attendee_count();

-- ============================================
-- 6. Storage bucket for post images
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for post-images bucket
CREATE POLICY "Anyone can view post images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'post-images');

CREATE POLICY "Authenticated users can upload post images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'post-images');

CREATE POLICY "Users can update their own post images"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own post images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);
