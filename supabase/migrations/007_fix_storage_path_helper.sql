-- Helper function to extract user_id from storage path
-- Storage paths are: bucket-name/user_id/...
CREATE OR REPLACE FUNCTION storage_user_id_from_path(path TEXT)
RETURNS UUID AS $$
DECLARE
  path_parts TEXT[];
  user_id_str TEXT;
BEGIN
  -- Split path by '/'
  path_parts := string_to_array(path, '/');
  
  -- Second element (index 2) should be user_id
  IF array_length(path_parts, 1) >= 2 THEN
    user_id_str := path_parts[2];
    
    -- Try to cast to UUID
    BEGIN
      RETURN user_id_str::UUID;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update storage policies to use the helper function
-- Note: Supabase storage policies use a different syntax
-- These policies are conceptual - actual implementation may vary

-- For pro-docs bucket: Update policy to use helper
DROP POLICY IF EXISTS "Users can view their own documents" ON storage.objects;
CREATE POLICY "Users can view their own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'pro-docs' AND
  auth.uid() IS NOT NULL AND
  EXISTS (
    SELECT 1 FROM users
    WHERE auth_user_id = auth.uid()
    AND id::text = (regexp_split_to_array(name, '/'))[2]
  )
);
