-- Add lifestyle fields for profile cards
-- work_style: remote, hybrid, location_based, retired
-- home_base: text field for home city
-- morning_person: boolean

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS work_style TEXT CHECK (work_style IS NULL OR work_style IN ('remote', 'hybrid', 'location_based', 'retired')),
ADD COLUMN IF NOT EXISTS home_base TEXT,
ADD COLUMN IF NOT EXISTS morning_person BOOLEAN;
