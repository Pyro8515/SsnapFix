-- Pro documents audit table
-- Tracks all changes to pro_documents for audit purposes
CREATE TABLE IF NOT EXISTS pro_documents_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES pro_documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'status_changed', 'deleted')),
    old_status TEXT,
    new_status TEXT,
    changed_fields JSONB, -- JSON object with changed field values
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL, -- Admin who made the change (if different from user_id)
    reason TEXT, -- Reason for the change (admin notes, system reason, etc.)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for audit queries
CREATE INDEX IF NOT EXISTS idx_pro_documents_audits_document_id ON pro_documents_audits(document_id);
CREATE INDEX IF NOT EXISTS idx_pro_documents_audits_user_id ON pro_documents_audits(user_id);
CREATE INDEX IF NOT EXISTS idx_pro_documents_audits_created_at ON pro_documents_audits(created_at);

-- Function to create audit records
CREATE OR REPLACE FUNCTION audit_pro_document_change()
RETURNS TRIGGER AS $$
DECLARE
    audit_action TEXT;
    changed_data JSONB := '{}'::JSONB;
    admin_user_id UUID;
BEGIN
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        audit_action := 'created';
    ELSIF TG_OP = 'UPDATE' THEN
        audit_action := 'updated';
        
        -- Check if status changed
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            audit_action := 'status_changed';
        END IF;
        
        -- Build changed fields JSON
        IF OLD.doc_type IS DISTINCT FROM NEW.doc_type THEN
            changed_data := changed_data || jsonb_build_object('doc_type', jsonb_build_object('old', OLD.doc_type, 'new', NEW.doc_type));
        END IF;
        IF OLD.doc_subtype IS DISTINCT FROM NEW.doc_subtype THEN
            changed_data := changed_data || jsonb_build_object('doc_subtype', jsonb_build_object('old', OLD.doc_subtype, 'new', NEW.doc_subtype));
        END IF;
        IF OLD.file_url IS DISTINCT FROM NEW.file_url THEN
            changed_data := changed_data || jsonb_build_object('file_url', jsonb_build_object('old', OLD.file_url, 'new', NEW.file_url));
        END IF;
        IF OLD.number IS DISTINCT FROM NEW.number THEN
            changed_data := changed_data || jsonb_build_object('number', jsonb_build_object('old', OLD.number, 'new', NEW.number));
        END IF;
        IF OLD.issuer IS DISTINCT FROM NEW.issuer THEN
            changed_data := changed_data || jsonb_build_object('issuer', jsonb_build_object('old', OLD.issuer, 'new', NEW.issuer));
        END IF;
        IF OLD.issued_at IS DISTINCT FROM NEW.issued_at THEN
            changed_data := changed_data || jsonb_build_object('issued_at', jsonb_build_object('old', OLD.issued_at, 'new', NEW.issued_at));
        END IF;
        IF OLD.expires_at IS DISTINCT FROM NEW.expires_at THEN
            changed_data := changed_data || jsonb_build_object('expires_at', jsonb_build_object('old', OLD.expires_at, 'new', NEW.expires_at));
        END IF;
        IF OLD.reason IS DISTINCT FROM NEW.reason THEN
            changed_data := changed_data || jsonb_build_object('reason', jsonb_build_object('old', OLD.reason, 'new', NEW.reason));
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        audit_action := 'deleted';
    END IF;
    
    -- Try to get admin user_id if current user is admin
    SELECT u.id INTO admin_user_id
    FROM users u
    JOIN admin_users au ON au.user_id = u.id
    WHERE u.auth_user_id = auth.uid();
    
    -- Insert audit record
    IF TG_OP = 'DELETE' THEN
        INSERT INTO pro_documents_audits (
            document_id,
            user_id,
            action,
            old_status,
            changed_by,
            reason
        ) VALUES (
            OLD.id,
            OLD.user_id,
            audit_action,
            OLD.status,
            admin_user_id,
            OLD.reason
        );
        RETURN OLD;
    ELSE
        INSERT INTO pro_documents_audits (
            document_id,
            user_id,
            action,
            old_status,
            new_status,
            changed_fields,
            changed_by,
            reason
        ) VALUES (
            NEW.id,
            NEW.user_id,
            audit_action,
            CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END,
            NEW.status,
            CASE WHEN jsonb_typeof(changed_data) = 'object' AND changed_data != '{}'::JSONB THEN changed_data ELSE NULL END,
            admin_user_id,
            NEW.reason
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for audit
DROP TRIGGER IF EXISTS trigger_audit_pro_document_insert ON pro_documents;
CREATE TRIGGER trigger_audit_pro_document_insert
    AFTER INSERT ON pro_documents
    FOR EACH ROW
    EXECUTE FUNCTION audit_pro_document_change();

DROP TRIGGER IF EXISTS trigger_audit_pro_document_update ON pro_documents;
CREATE TRIGGER trigger_audit_pro_document_update
    AFTER UPDATE ON pro_documents
    FOR EACH ROW
    EXECUTE FUNCTION audit_pro_document_change();

DROP TRIGGER IF EXISTS trigger_audit_pro_document_delete ON pro_documents;
CREATE TRIGGER trigger_audit_pro_document_delete
    AFTER DELETE ON pro_documents
    FOR EACH ROW
    EXECUTE FUNCTION audit_pro_document_change();

