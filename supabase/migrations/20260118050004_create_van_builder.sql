-- Migration: Create Van Builder Community Tables
-- Description: Channels, messages, experts, and resources

-- Van Builder Channels
CREATE TABLE public.van_builder_channels (
    id TEXT PRIMARY KEY, -- e.g., 'electrical', 'solar', 'plumbing'
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT NOT NULL,
    color TEXT NOT NULL, -- Hex color
    member_count INTEGER DEFAULT 0,
    trending BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Channel Memberships
CREATE TABLE public.channel_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id TEXT NOT NULL REFERENCES public.van_builder_channels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_read_at TIMESTAMPTZ,
    notifications_enabled BOOLEAN DEFAULT TRUE,

    CONSTRAINT unique_channel_member UNIQUE (channel_id, user_id)
);

CREATE INDEX idx_channel_members_channel ON public.channel_memberships(channel_id);
CREATE INDEX idx_channel_members_user ON public.channel_memberships(user_id);

-- Channel Messages
CREATE TABLE public.channel_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id TEXT NOT NULL REFERENCES public.van_builder_channels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',

    -- Engagement
    likes INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    liked_by UUID[] DEFAULT '{}',

    -- Threading
    parent_id UUID REFERENCES public.channel_messages(id) ON DELETE CASCADE,

    -- Moderation
    is_pinned BOOLEAN DEFAULT FALSE,
    is_expert_post BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_channel_messages_channel ON public.channel_messages(channel_id);
CREATE INDEX idx_channel_messages_user ON public.channel_messages(user_id);
CREATE INDEX idx_channel_messages_parent ON public.channel_messages(parent_id);
CREATE INDEX idx_channel_messages_created ON public.channel_messages(created_at DESC);

-- Experts Table
CREATE TABLE public.van_builder_experts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    specialty TEXT NOT NULL,
    bio TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT TRUE,
    available_for_booking BOOLEAN DEFAULT TRUE,
    hourly_rate DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_expert UNIQUE (user_id)
);

CREATE INDEX idx_experts_specialty ON public.van_builder_experts(specialty);
CREATE INDEX idx_experts_rating ON public.van_builder_experts(rating DESC);

-- Resources Table
CREATE TABLE public.van_builder_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    file_url TEXT,
    thumbnail_url TEXT,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    views INTEGER DEFAULT 0,
    saves INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_resources_category ON public.van_builder_resources(category);
CREATE INDEX idx_resources_views ON public.van_builder_resources(views DESC);

-- RLS Policies
ALTER TABLE public.van_builder_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channel_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.van_builder_experts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.van_builder_resources ENABLE ROW LEVEL SECURITY;

-- Channels are public
CREATE POLICY "Anyone can view channels" ON public.van_builder_channels
    FOR SELECT USING (true);

-- Memberships
CREATE POLICY "Users can view memberships" ON public.channel_memberships
    FOR SELECT USING (true);

CREATE POLICY "Users can join channels" ON public.channel_memberships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave channels" ON public.channel_memberships
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can update their membership" ON public.channel_memberships
    FOR UPDATE USING (auth.uid() = user_id);

-- Messages
CREATE POLICY "Anyone can view channel messages" ON public.channel_messages
    FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Users can post messages" ON public.channel_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own messages" ON public.channel_messages
    FOR UPDATE USING (auth.uid() = user_id);

-- Experts
CREATE POLICY "Anyone can view experts" ON public.van_builder_experts
    FOR SELECT USING (true);

-- Resources
CREATE POLICY "Anyone can view resources" ON public.van_builder_resources
    FOR SELECT USING (true);

CREATE POLICY "Users can upload resources" ON public.van_builder_resources
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

-- Update member count trigger
CREATE OR REPLACE FUNCTION public.update_channel_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.van_builder_channels
        SET member_count = member_count + 1
        WHERE id = NEW.channel_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.van_builder_channels
        SET member_count = member_count - 1
        WHERE id = OLD.channel_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_channel_member_change
    AFTER INSERT OR DELETE ON public.channel_memberships
    FOR EACH ROW EXECUTE FUNCTION public.update_channel_member_count();

-- Update reply count trigger
CREATE OR REPLACE FUNCTION public.update_reply_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
        UPDATE public.channel_messages
        SET reply_count = reply_count + 1
        WHERE id = NEW.parent_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_reply
    AFTER INSERT ON public.channel_messages
    FOR EACH ROW EXECUTE FUNCTION public.update_reply_count();

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.channel_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.channel_memberships;

-- Seed initial channels
INSERT INTO public.van_builder_channels (id, name, description, icon, color, sort_order, trending) VALUES
    ('electrical', 'Electrical & Wiring', 'Electrical systems, wiring, batteries, and power management', 'bolt.fill', '#CC6633', 1, true),
    ('solar', 'Solar & Off-Grid', 'Solar panels, charge controllers, and off-grid power solutions', 'sun.max.fill', '#F59E0B', 2, true),
    ('plumbing', 'Plumbing & Water', 'Water tanks, pumps, filtration, and plumbing systems', 'drop.fill', '#3B82F6', 3, false),
    ('hvac', 'Heating & Cooling', 'Heaters, AC units, ventilation, and insulation', 'thermometer', '#DC2626', 4, false),
    ('interior', 'Interior Design', 'Layout planning, furniture building, and space optimization', 'square.grid.2x2', '#22C55E', 5, true),
    ('general', 'General Build Help', 'General questions, build progress, and troubleshooting', 'wrench.fill', '#6B7280', 6, false);
