-- ============================================
-- Add RPC function for soft-deleting community posts
-- Bypasses RLS to avoid SELECT policy (deleted_at IS NULL) blocking the UPDATE
-- Performs its own auth check internally
-- ============================================

CREATE OR REPLACE FUNCTION soft_delete_community_post(post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    rows_affected INT;
BEGIN
    -- Verify the caller is the post author
    UPDATE community_posts
    SET deleted_at = NOW()
    WHERE id = post_id
      AND author_id = auth.uid()
      AND deleted_at IS NULL;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    RETURN rows_affected > 0;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION soft_delete_community_post(UUID) TO authenticated;
