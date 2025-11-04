-- Enable RLS on pro_documents_audits table
ALTER TABLE pro_documents_audits ENABLE ROW LEVEL SECURITY;

-- Pro documents audits policies
-- Users can view audit records for their own documents
DROP POLICY IF EXISTS "Users can view their own document audits" ON pro_documents_audits;
CREATE POLICY "Users can view their own document audits"
    ON pro_documents_audits FOR SELECT
    USING (user_id = auth_user_id());

-- Admins can view all audit records
DROP POLICY IF EXISTS "Admins can view all document audits" ON pro_documents_audits;
CREATE POLICY "Admins can view all document audits"
    ON pro_documents_audits FOR SELECT
    USING (is_admin(auth_user_id()));

-- Audit records are created automatically by triggers, no manual inserts allowed
-- Only system can insert (via SECURITY DEFINER function)

