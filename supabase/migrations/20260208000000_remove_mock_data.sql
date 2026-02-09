-- Migration: Remove Mock Data
-- Description: Clean up all seed/test data for production readiness

-- ============================================================
-- Delete test users and all their related data
-- ============================================================
DO $$
DECLARE
    test_user_ids UUID[];
BEGIN
    -- Collect all test user IDs
    SELECT ARRAY_AGG(id) INTO test_user_ids
    FROM auth.users
    WHERE email IN ('sarah@test.com', 'marcus@test.com', 'luna@test.com', 'jake@test.com', 'emma@test.com', 'alex@test.com');

    IF test_user_ids IS NOT NULL THEN
        -- Delete related data (order matters for foreign keys)
        DELETE FROM public.channel_messages WHERE user_id = ANY(test_user_ids);
        DELETE FROM public.van_builder_experts WHERE user_id = ANY(test_user_ids);
        DELETE FROM public.friends WHERE requester_id = ANY(test_user_ids) OR addressee_id = ANY(test_user_ids);
        DELETE FROM public.activities WHERE host_id = ANY(test_user_ids);
        DELETE FROM public.profiles WHERE id = ANY(test_user_ids);
        DELETE FROM auth.users WHERE id = ANY(test_user_ids);

        RAISE NOTICE 'Removed % test users and their related data', array_length(test_user_ids, 1);
    ELSE
        RAISE NOTICE 'No test users found - already clean';
    END IF;
END $$;

-- ============================================================
-- Delete seeded van builder resources
-- ============================================================
DELETE FROM public.van_builder_resources WHERE title IN (
    'Complete Electrical Wiring Guide',
    '400W Solar Setup Tutorial',
    'DIY Water System Design',
    'Insulation Materials Compared',
    'Space-Saving Furniture Ideas',
    'Lithium Battery Guide',
    'Solar System Sizing Calculator',
    'Insulation Best Practices',
    'Water System Diagram Templates',
    'Battery Bank Wiring Diagrams',
    'Ventilation Fan Installation Guide'
);

-- ============================================================
-- Reset channel member counts to 0
-- ============================================================
UPDATE public.van_builder_channels SET member_count = 0
WHERE id IN ('electrical', 'solar', 'plumbing', 'hvac', 'interior', 'general');

-- ============================================================
-- Drop seed helper functions
-- ============================================================
DROP FUNCTION IF EXISTS public.seed_test_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.seed_test_activities(UUID);

-- Revoke grants (in case drop didn't cascade)
-- These will no-op if already dropped
DO $$
BEGIN
    EXECUTE 'REVOKE ALL ON FUNCTION public.seed_test_profile FROM authenticated';
EXCEPTION WHEN undefined_function THEN
    -- Function already dropped
END $$;

DO $$
BEGIN
    EXECUTE 'REVOKE ALL ON FUNCTION public.seed_test_activities FROM authenticated';
EXCEPTION WHEN undefined_function THEN
    -- Function already dropped
END $$;
