-- Function: send_document_expiry_reminders
-- Checks for documents expiring in 14 days, 3 days, or already expired
-- Creates notifications for reminders that haven't been sent yet
CREATE OR REPLACE FUNCTION send_document_expiry_reminders()
RETURNS TABLE(
    reminders_sent INTEGER,
    documents_checked INTEGER,
    affected_users UUID[]
) AS $$
DECLARE
    affected_user_ids UUID[];
    reminder_count INTEGER := 0;
    doc_count INTEGER := 0;
    doc_record RECORD;
    reminder_type TEXT;
    days_until_expiry INTEGER;
    notification_id UUID;
BEGIN
    -- Check all documents that are approved or pending and have an expiry date
    FOR doc_record IN
        SELECT 
            pd.id,
            pd.user_id,
            pd.doc_type,
            pd.doc_subtype,
            pd.expires_at,
            pd.status,
            u.auth_user_id
        FROM pro_documents pd
        JOIN users u ON u.id = pd.user_id
        WHERE pd.status IN ('approved', 'pending', 'manual_review')
        AND pd.expires_at IS NOT NULL
        AND pd.expires_at > CURRENT_DATE - INTERVAL '1 day' -- Include expired up to 1 day ago
        ORDER BY pd.expires_at ASC
    LOOP
        doc_count := doc_count + 1;
        
        -- Calculate days until expiry
        days_until_expiry := (doc_record.expires_at - CURRENT_DATE)::INTEGER;
        
        -- Determine reminder type
        IF days_until_expiry < 0 THEN
            -- Document is expired
            reminder_type := 'expired';
        ELSIF days_until_expiry <= 3 THEN
            -- 3 days or less
            reminder_type := '3_days';
        ELSIF days_until_expiry <= 14 THEN
            -- 14 days or less
            reminder_type := '14_days';
        ELSE
            -- Too far in the future, skip
            CONTINUE;
        END IF;
        
        -- Check if reminder already sent
        IF EXISTS (
            SELECT 1 FROM document_expiry_reminders
            WHERE document_id = doc_record.id
            AND reminder_type = reminder_type
        ) THEN
            CONTINUE;
        END IF;
        
        -- Create notification
        INSERT INTO notifications (
            user_id,
            type,
            title,
            body,
            data,
            channel,
            status
        ) VALUES (
            doc_record.user_id,
            CASE 
                WHEN reminder_type = 'expired' THEN 'document_expired'
                ELSE 'document_expiry'
            END,
            CASE 
                WHEN reminder_type = 'expired' THEN 'Document Expired'
                WHEN reminder_type = '3_days' THEN 'Document Expiring Soon'
                ELSE 'Document Expiring Soon'
            END,
            CASE 
                WHEN reminder_type = 'expired' THEN 
                    'Your ' || doc_record.doc_type || 
                    COALESCE(' (' || doc_record.doc_subtype || ')', '') || 
                    ' document has expired. Please upload a new document to maintain your verification status.'
                WHEN reminder_type = '3_days' THEN 
                    'Your ' || doc_record.doc_type || 
                    COALESCE(' (' || doc_record.doc_subtype || ')', '') || 
                    ' document expires in ' || days_until_expiry || ' days. Please renew it soon.'
                ELSE 
                    'Your ' || doc_record.doc_type || 
                    COALESCE(' (' || doc_record.doc_subtype || ')', '') || 
                    ' document expires in ' || days_until_expiry || ' days.'
            END,
            jsonb_build_object(
                'document_id', doc_record.id,
                'doc_type', doc_record.doc_type,
                'doc_subtype', doc_record.doc_subtype,
                'expires_at', doc_record.expires_at,
                'days_until_expiry', days_until_expiry
            ),
            'in_app', -- Default to in-app, will be sent via push/SMS based on preferences
            'pending'
        ) RETURNING id INTO notification_id;
        
        -- Record reminder
        INSERT INTO document_expiry_reminders (
            document_id,
            user_id,
            reminder_type,
            notification_id
        ) VALUES (
            doc_record.id,
            doc_record.user_id,
            reminder_type,
            notification_id
        ) ON CONFLICT (document_id, reminder_type) DO NOTHING;
        
        reminder_count := reminder_count + 1;
        
        -- Track affected user
        IF NOT (doc_record.user_id = ANY(affected_user_ids)) THEN
            affected_user_ids := array_append(affected_user_ids, doc_record.user_id);
        END IF;
    END LOOP;
    
    RETURN QUERY
    SELECT 
        reminder_count,
        doc_count,
        COALESCE(affected_user_ids, ARRAY[]::UUID[]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: process_document_expiry_demotions
-- Called after expire_pro_documents() to send demotion notices
-- This should be called after documents are marked as expired
CREATE OR REPLACE FUNCTION process_document_expiry_demotions()
RETURNS TABLE(
    notices_sent INTEGER,
    affected_users UUID[]
) AS $$
DECLARE
    affected_user_ids UUID[];
    notice_count INTEGER := 0;
    user_record RECORD;
    notification_id UUID;
BEGIN
    -- Find users whose verification_status was demoted due to expired documents
    -- This should be called after recompute_pro_trade_compliance updates verification_status
    FOR user_record IN
        SELECT DISTINCT u.id, u.auth_user_id, u.verification_status
        FROM users u
        JOIN professional_profiles pp ON pp.user_id = u.id
        WHERE u.verification_status IN ('pending', 'rejected')
        AND EXISTS (
            SELECT 1 FROM pro_documents pd
            WHERE pd.user_id = u.id
            AND pd.status = 'expired'
            AND pd.expires_at >= CURRENT_DATE - INTERVAL '7 days' -- Recently expired
        )
        AND NOT EXISTS (
            -- Check if we already sent a demotion notice recently (within 7 days)
            SELECT 1 FROM notifications n
            WHERE n.user_id = u.id
            AND n.type = 'document_expired'
            AND n.title LIKE '%verification status%'
            AND n.created_at > CURRENT_DATE - INTERVAL '7 days'
        )
    LOOP
        -- Create demotion notice
        INSERT INTO notifications (
            user_id,
            type,
            title,
            body,
            data,
            channel,
            status
        ) VALUES (
            user_record.id,
            'document_expired',
            'Verification Status Updated',
            'Your verification status has been updated due to expired documents. Please upload renewed documents to restore your approved status.',
            jsonb_build_object(
                'verification_status', user_record.verification_status,
                'reason', 'expired_documents'
            ),
            'in_app',
            'pending'
        ) RETURNING id INTO notification_id;
        
        notice_count := notice_count + 1;
        
        -- Track affected user
        IF NOT (user_record.id = ANY(affected_user_ids)) THEN
            affected_user_ids := array_append(affected_user_ids, user_record.id);
        END IF;
    END LOOP;
    
    RETURN QUERY
    SELECT 
        notice_count,
        COALESCE(affected_user_ids, ARRAY[]::UUID[]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

