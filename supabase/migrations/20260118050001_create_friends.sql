-- Migration: Create Friends and Matching Tables
-- Description: Friend requests, swipes, and dating matches

-- Friend Request Status Enum
CREATE TYPE friend_status AS ENUM ('pending', 'accepted', 'declined', 'blocked');

-- Friends/Connections Table
CREATE TABLE public.friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status friend_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent duplicate requests
    CONSTRAINT unique_friend_pair UNIQUE (requester_id, addressee_id),
    -- Prevent self-friending
    CONSTRAINT no_self_friend CHECK (requester_id != addressee_id)
);

CREATE INDEX idx_friends_requester ON public.friends(requester_id);
CREATE INDEX idx_friends_addressee ON public.friends(addressee_id);
CREATE INDEX idx_friends_status ON public.friends(status);

-- Dating Matches Table (separate from friends)
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user1_liked_at TIMESTAMPTZ,
    user2_liked_at TIMESTAMPTZ,
    matched_at TIMESTAMPTZ,
    is_match BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_match_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT ordered_pair CHECK (user1_id < user2_id)
);

CREATE INDEX idx_matches_user1 ON public.matches(user1_id);
CREATE INDEX idx_matches_user2 ON public.matches(user2_id);
CREATE INDEX idx_matches_is_match ON public.matches(is_match);

-- Swipes/Likes Table (for discovery)
CREATE TABLE public.swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    direction TEXT CHECK (direction IN ('left', 'right', 'up')) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_swipe UNIQUE (swiper_id, swiped_id)
);

CREATE INDEX idx_swipes_swiper ON public.swipes(swiper_id);
CREATE INDEX idx_swipes_swiped ON public.swipes(swiped_id);

-- RLS Policies
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;

-- Friends policies
CREATE POLICY "Users can view their own friend requests" ON public.friends
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can send friend requests" ON public.friends
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update friend requests they're involved in" ON public.friends
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can delete their friend connections" ON public.friends
    FOR DELETE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Matches policies
CREATE POLICY "Users can view their own matches" ON public.matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create matches" ON public.matches
    FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update their matches" ON public.matches
    FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Swipes policies
CREATE POLICY "Users can only see their own swipes" ON public.swipes
    FOR SELECT USING (auth.uid() = swiper_id);

CREATE POLICY "Users can create their own swipes" ON public.swipes
    FOR INSERT WITH CHECK (auth.uid() = swiper_id);

-- Function to check for mutual match
CREATE OR REPLACE FUNCTION public.check_mutual_match()
RETURNS TRIGGER AS $$
DECLARE
    other_swipe RECORD;
BEGIN
    IF NEW.direction = 'right' THEN
        -- Check if the other person also swiped right
        SELECT * INTO other_swipe FROM public.swipes
        WHERE swiper_id = NEW.swiped_id
        AND swiped_id = NEW.swiper_id
        AND direction = 'right';

        IF FOUND THEN
            -- Create or update match
            INSERT INTO public.matches (user1_id, user2_id, matched_at, is_match)
            VALUES (
                LEAST(NEW.swiper_id, NEW.swiped_id),
                GREATEST(NEW.swiper_id, NEW.swiped_id),
                NOW(),
                TRUE
            )
            ON CONFLICT (user1_id, user2_id)
            DO UPDATE SET matched_at = NOW(), is_match = TRUE;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_swipe_check_match
    AFTER INSERT ON public.swipes
    FOR EACH ROW EXECUTE FUNCTION public.check_mutual_match();

-- Enable Realtime for friend requests and matches
ALTER PUBLICATION supabase_realtime ADD TABLE public.friends;
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
