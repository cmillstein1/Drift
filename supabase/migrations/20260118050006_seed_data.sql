-- Migration: Seed Test Data
-- Description: Mock data for development and testing
-- NOTE: Test user profiles will be created when users sign up through the app

-- ============================================================
-- Van Builder Resources (no auth required)
-- ============================================================
INSERT INTO public.van_builder_resources (id, title, description, category, thumbnail_url, views, saves) VALUES
    (gen_random_uuid(), 'Complete Electrical Wiring Guide', 'Step-by-step guide to wiring your van from scratch, including battery banks and shore power.', 'Electrical', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', 2543, 892),
    (gen_random_uuid(), '400W Solar Setup Tutorial', 'How to install a 400W solar system with MPPT controller for full off-grid capability.', 'Solar', 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400', 3891, 1247),
    (gen_random_uuid(), 'DIY Water System Design', 'Design and build a complete fresh/grey water system with 12V pump and filtration.', 'Plumbing', 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=400', 1876, 654),
    (gen_random_uuid(), 'Insulation Materials Compared', 'Wool vs foam vs Thinsulate - comprehensive comparison for van insulation.', 'HVAC', 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400', 2134, 789),
    (gen_random_uuid(), 'Space-Saving Furniture Ideas', '20 clever furniture designs that maximize space in small vans.', 'Interior', 'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?w=400', 4521, 1893),
    (gen_random_uuid(), 'Lithium Battery Guide', 'Everything you need to know about LiFePO4 batteries for van life.', 'Electrical', 'https://images.unsplash.com/photo-1619641805634-6e4a3fc1ab00?w=400', 3245, 1102);

-- ============================================================
-- Update channel member counts with realistic numbers
-- ============================================================
UPDATE public.van_builder_channels SET member_count = 3421 WHERE id = 'electrical';
UPDATE public.van_builder_channels SET member_count = 2856 WHERE id = 'solar';
UPDATE public.van_builder_channels SET member_count = 1943 WHERE id = 'plumbing';
UPDATE public.van_builder_channels SET member_count = 1567 WHERE id = 'hvac';
UPDATE public.van_builder_channels SET member_count = 2234 WHERE id = 'interior';
UPDATE public.van_builder_channels SET member_count = 4521 WHERE id = 'general';

-- ============================================================
-- Function to seed test data after a user signs up
-- Call this from the app after authentication to populate test data
-- ============================================================
CREATE OR REPLACE FUNCTION public.seed_test_profile(
    p_user_id UUID,
    p_name TEXT,
    p_bio TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL,
    p_location TEXT DEFAULT NULL,
    p_lifestyle TEXT DEFAULT 'van_life',
    p_looking_for TEXT DEFAULT 'both',
    p_interests TEXT[] DEFAULT '{}'
) RETURNS void AS $$
BEGIN
    UPDATE public.profiles SET
        name = p_name,
        bio = p_bio,
        avatar_url = p_avatar_url,
        location = p_location,
        lifestyle = p_lifestyle,
        looking_for = p_looking_for,
        interests = p_interests,
        verified = TRUE,
        onboarding_completed = TRUE,
        birthday = CURRENT_DATE - INTERVAL '25 years' - (random() * 15 * 365 || ' days')::INTERVAL
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.seed_test_profile TO authenticated;

-- ============================================================
-- Function to create test activities for a user
-- ============================================================
CREATE OR REPLACE FUNCTION public.seed_test_activities(p_user_id UUID) RETURNS void AS $$
DECLARE
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;

    IF v_profile IS NULL THEN
        RAISE EXCEPTION 'Profile not found for user %', p_user_id;
    END IF;

    -- Create a sample activity
    INSERT INTO public.activities (host_id, title, description, category, location, image_url, starts_at, duration_minutes, max_attendees)
    VALUES (
        p_user_id,
        'Coffee & Chat Meetup',
        'Looking to meet fellow travelers! Let''s grab coffee and share stories.',
        'social',
        COALESCE(v_profile.location, 'Local Coffee Shop'),
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
        NOW() + INTERVAL '3 days',
        90,
        6
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.seed_test_activities TO authenticated;
