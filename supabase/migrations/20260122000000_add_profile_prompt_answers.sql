-- Migration: Add profile prompt answers field
-- Description: Adds a JSON field to store flexible prompt answers for dating profiles

-- Add new column to profiles table
ALTER TABLE public.profiles
ADD COLUMN prompt_answers JSONB DEFAULT '[]'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.prompt_answers IS 'Array of prompt answers: [{"prompt": "text", "answer": "text"}, ...]';

-- Add index for JSON queries
CREATE INDEX idx_profiles_prompt_answers ON public.profiles USING GIN (prompt_answers);
