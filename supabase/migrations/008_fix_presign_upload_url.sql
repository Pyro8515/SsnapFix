-- Note: This migration is informational
-- The presign upload URL logic is handled in the Edge Function
-- This file documents the expected storage path structure

-- Storage paths follow this structure:
-- pro-docs/{user_id}/{doc_type}/{doc_subtype|default}/{uuid}.{extension}
-- Example: pro-docs/550e8400-e29b-41d4-a716-446655440000/plumbing_license/master/123e4567-e89b-12d3-a456-426614174000.pdf

-- The Edge Function api-pro-docs-presign generates these paths
-- Storage policies ensure users can only access their own paths
