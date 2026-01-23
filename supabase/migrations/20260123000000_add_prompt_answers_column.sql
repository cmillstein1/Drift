-- Migration: Add prompt_answers column to profiles table
-- Description: Adds JSONB column to store flexible prompt answers for dating profiles
-- This migration adds the prompt_answers column that was missing from the original add_profile_prompts migration

-- Add the column if it doesn't exist (safe to run multiple times)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'prompt_answers'
    ) THEN
        ALTER TABLE public.profiles
        ADD COLUMN prompt_answers JSONB DEFAULT '[]'::jsonb;
        
        COMMENT ON COLUMN public.profiles.prompt_answers IS 'Array of prompt answers: [{"prompt": "text", "answer": "text"}, ...]';
        
        CREATE INDEX idx_profiles_prompt_answers ON public.profiles USING GIN (prompt_answers);
    END IF;
END $$;
