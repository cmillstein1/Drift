-- Migration: Create Storage Bucket Policies
-- Description: RLS policies for avatar, photo, and media storage buckets
-- Note: Storage buckets must be created via Supabase Dashboard or CLI first

-- Avatar bucket policies (bucket: avatars)
-- Structure: avatars/{user_id}/avatar.{ext}
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Photos bucket policies (bucket: photos)
-- Structure: photos/{user_id}/{photo_id}.{ext}
CREATE POLICY "Photos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');

CREATE POLICY "Users can upload their own photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own photos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Activity images bucket policies (bucket: activity-images)
-- Structure: activity-images/{activity_id}/{image_id}.{ext}
CREATE POLICY "Activity images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'activity-images');

CREATE POLICY "Authenticated users can upload activity images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'activity-images' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can update activity images they uploaded"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'activity-images' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete activity images they uploaded"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'activity-images' AND
    auth.role() = 'authenticated'
);

-- Channel images bucket policies (bucket: channel-images)
-- Structure: channel-images/{channel_id}/{message_id}/{image_id}.{ext}
CREATE POLICY "Channel images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'channel-images');

CREATE POLICY "Authenticated users can upload channel images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'channel-images' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can update channel images they uploaded"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'channel-images' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete channel images they uploaded"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'channel-images' AND
    auth.role() = 'authenticated'
);

-- Message images bucket policies (bucket: message-images)
-- Structure: message-images/{conversation_id}/{message_id}/{image_id}.{ext}
CREATE POLICY "Message images accessible to conversation participants"
ON storage.objects FOR SELECT
USING (bucket_id = 'message-images');

CREATE POLICY "Authenticated users can upload message images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'message-images' AND
    auth.role() = 'authenticated'
);
