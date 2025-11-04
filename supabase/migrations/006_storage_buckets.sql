-- Create storage buckets
-- Note: This requires the storage extension to be enabled
-- Run this via Supabase Dashboard SQL Editor or ensure storage extension is enabled

-- Create pro-avatars bucket (public read)
INSERT INTO storage.buckets (id, name, public)
VALUES ('pro-avatars', 'pro-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create pro-docs bucket (private)
INSERT INTO storage.buckets (id, name, public)
VALUES ('pro-docs', 'pro-docs', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for pro-avatars
-- Policy: Anyone can read public avatars
DROP POLICY IF EXISTS "Public avatars are viewable by everyone" ON storage.objects;
CREATE POLICY "Public avatars are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'pro-avatars');

-- Policy: Authenticated users can upload to their own path
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'pro-avatars' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can update their own avatar
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'pro-avatars' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can delete their own avatar
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'pro-avatars' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policies for pro-docs
-- Policy: Users can read their own documents
DROP POLICY IF EXISTS "Users can view their own documents" ON storage.objects;
CREATE POLICY "Users can view their own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'pro-docs' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can upload their own documents
DROP POLICY IF EXISTS "Users can upload their own documents" ON storage.objects;
CREATE POLICY "Users can upload their own documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'pro-docs' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can update their own documents
DROP POLICY IF EXISTS "Users can update their own documents" ON storage.objects;
CREATE POLICY "Users can update their own documents"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'pro-docs' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Admins can view all documents
DROP POLICY IF EXISTS "Admins can view all documents" ON storage.objects;
CREATE POLICY "Admins can view all documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'pro-docs' AND
  EXISTS (
    SELECT 1 FROM users u
    JOIN admin_users au ON au.user_id = u.id
    WHERE u.auth_user_id = auth.uid()
  )
);
