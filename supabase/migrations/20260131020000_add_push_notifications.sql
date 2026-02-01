-- Migration: Add Push Notification Support
-- Description: Add FCM token and notification preferences to profiles

-- Add FCM token column for push notification targeting
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add notification preferences as JSONB for flexible category management
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS notification_prefs JSONB DEFAULT '{"newMessages": true, "newMatches": true, "nearbyTravelers": true, "eventUpdates": true}'::jsonb;

-- Index for efficient FCM token lookups when sending notifications
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON public.profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- Comment for documentation
COMMENT ON COLUMN public.profiles.fcm_token IS 'Firebase Cloud Messaging token for push notifications';
COMMENT ON COLUMN public.profiles.notification_prefs IS 'User notification preferences by category: newMessages, newMatches, nearbyTravelers, eventUpdates';
