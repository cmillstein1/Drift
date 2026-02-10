-- Add gender column to profiles table.
-- Stores the user's gender identity: "Male", "Female", "Non-binary", "Prefer not to say".
-- Separate from orientation which stores dating preference (who they're interested in).

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;

-- Migrate existing orientation values that are gender identities to the new gender column.
-- Gender values from onboarding: "Male", "Female", "Non-binary", "Prefer not to say"
-- Dating preference values from settings: "women", "men", "non-binary", "everyone"
-- If orientation contains a gender identity value, copy it to gender and clear orientation.
UPDATE profiles
SET gender = orientation, orientation = NULL
WHERE orientation IN ('Male', 'Female', 'Non-binary', 'Prefer not to say');
