-- Migration: Fix reports.reported_user_id constraint
-- Description: Allow reported_user_id to be NULL so ON DELETE SET NULL works when a user is deleted

ALTER TABLE public.reports ALTER COLUMN reported_user_id DROP NOT NULL;
