-- View: v_user_active_docs - Latest active/approved documents per user
CREATE OR REPLACE VIEW v_user_active_docs AS
SELECT DISTINCT ON (user_id, doc_type, COALESCE(doc_subtype, ''))
    id,
    user_id,
    doc_type,
    doc_subtype,
    status,
    file_url,
    number,
    issuer,
    issued_at,
    expires_at,
    reason,
    created_at,
    updated_at
FROM pro_documents
WHERE status IN ('approved', 'pending', 'manual_review')
ORDER BY user_id, doc_type, COALESCE(doc_subtype, ''), updated_at DESC;

-- Function: recompute_pro_trade_compliance
-- Recomputes trade compliance for a user based on their documents and requirements
CREATE OR REPLACE FUNCTION recompute_pro_trade_compliance(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
    user_trades TEXT[];
    trade_item TEXT;
    required_docs RECORD;
    user_docs RECORD;
    all_compliant BOOLEAN;
    missing_docs TEXT[];
    compliance_reason TEXT;
BEGIN
    -- Get user's trades from professional_profiles
    SELECT COALESCE(services, ARRAY[]::TEXT[]) INTO user_trades
    FROM professional_profiles
    WHERE user_id = target_user_id;

    -- If no trades, clear compliance records
    IF user_trades IS NULL OR array_length(user_trades, 1) IS NULL THEN
        DELETE FROM pro_trade_compliance WHERE user_id = target_user_id;
        RETURN;
    END IF;

    -- Check compliance for each trade
    FOREACH trade_item IN ARRAY user_trades
    LOOP
        -- Get all required docs for this trade (global + trade-specific)
        -- Union: global requirements (trade IS NULL) + trade-specific requirements
        all_compliant := true;
        missing_docs := ARRAY[]::TEXT[];

        -- Check global requirements first
        FOR required_docs IN
            SELECT doc_type, doc_subtype, is_critical, trade
            FROM trade_requirements
            WHERE (trade IS NULL OR trade = trade_item)
            AND is_required = true
            ORDER BY trade NULLS FIRST
        LOOP
            -- Check if user has this document in approved/pending status and not expired
            SELECT EXISTS (
                SELECT 1 FROM v_user_active_docs
                WHERE user_id = target_user_id
                AND doc_type = required_docs.doc_type
                AND COALESCE(doc_subtype, '') = COALESCE(required_docs.doc_subtype, '')
                AND status IN ('approved', 'pending', 'manual_review')
                AND (expires_at IS NULL OR expires_at > CURRENT_DATE)
            ) INTO user_docs;

            IF NOT FOUND OR user_docs IS NULL THEN
                all_compliant := false;
                missing_docs := array_append(
                    missing_docs,
                    required_docs.doc_type || 
                    CASE WHEN required_docs.doc_subtype IS NOT NULL THEN ' (' || required_docs.doc_subtype || ')' ELSE '' END
                );
            END IF;
        END LOOP;

        -- Special handling for government_id: must be verified via Stripe Identity
        IF EXISTS (
            SELECT 1 FROM trade_requirements
            WHERE (trade IS NULL OR trade = trade_item)
            AND doc_type = 'government_id'
            AND is_required = true
        ) THEN
            IF NOT EXISTS (
                SELECT 1 FROM professional_profiles
                WHERE user_id = target_user_id
                AND identity_status = 'verified'
            ) THEN
                all_compliant := false;
                missing_docs := array_append(missing_docs, 'government_id (Stripe Identity verification)');
            END IF;
        END IF;

        -- Build reason string
        IF NOT all_compliant THEN
            compliance_reason := 'Missing required documents: ' || array_to_string(missing_docs, ', ');
        ELSE
            compliance_reason := NULL;
        END IF;

        -- Upsert compliance record
        INSERT INTO pro_trade_compliance (user_id, trade, compliant, reason, updated_at)
        VALUES (target_user_id, trade_item, all_compliant, compliance_reason, NOW())
        ON CONFLICT (user_id, trade) 
        DO UPDATE SET
            compliant = all_compliant,
            reason = compliance_reason,
            updated_at = NOW();
    END LOOP;

    -- Remove compliance records for trades the user no longer has
    DELETE FROM pro_trade_compliance
    WHERE user_id = target_user_id
    AND trade <> ALL(user_trades);

    -- Update user verification_status if needed
    -- Global verification_status = approved only if:
    -- 1. Identity approved (via Stripe Identity)
    -- 2. At least one trade compliant
    -- 3. No critical global docs missing/expired
    UPDATE users
    SET verification_status = CASE
        WHEN EXISTS (
            SELECT 1 FROM professional_profiles
            WHERE user_id = target_user_id
            AND identity_status = 'verified'
        )
        AND EXISTS (
            SELECT 1 FROM pro_trade_compliance
            WHERE user_id = target_user_id
            AND compliant = true
        )
        AND NOT EXISTS (
            -- Check for expired critical global docs
            SELECT 1 FROM trade_requirements tr
            WHERE tr.trade IS NULL
            AND tr.is_critical = true
            AND tr.is_required = true
            AND NOT EXISTS (
                SELECT 1 FROM v_user_active_docs vd
                WHERE vd.user_id = target_user_id
                AND vd.doc_type = tr.doc_type
                AND COALESCE(vd.doc_subtype, '') = COALESCE(tr.doc_subtype, '')
                AND vd.status = 'approved'
                AND (vd.expires_at IS NULL OR vd.expires_at > CURRENT_DATE)
            )
        )
        THEN 'approved'
        WHEN EXISTS (
            SELECT 1 FROM professional_profiles
            WHERE user_id = target_user_id
            AND identity_status = 'failed'
        )
        THEN 'rejected'
        ELSE 'pending'
    END
    WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: expire_pro_documents
-- Marks expired documents and triggers compliance recomputation
CREATE OR REPLACE FUNCTION expire_pro_documents()
RETURNS TABLE(expired_count INTEGER, affected_users UUID[]) AS $$
DECLARE
    affected_user_ids UUID[];
BEGIN
    -- Mark expired documents
    WITH expired AS (
        UPDATE pro_documents
        SET status = 'expired',
            updated_at = NOW()
        WHERE status IN ('approved', 'pending', 'manual_review')
        AND expires_at IS NOT NULL
        AND expires_at < CURRENT_DATE
        RETURNING user_id
    )
    SELECT array_agg(DISTINCT user_id) INTO affected_user_ids
    FROM expired;

    -- Recompute compliance for affected users
    IF affected_user_ids IS NOT NULL THEN
        PERFORM recompute_pro_trade_compliance(user_id) FROM unnest(affected_user_ids) AS user_id;
        
        -- Process demotion notices after compliance recomputation
        -- This will send notifications to users whose verification_status was demoted
        PERFORM process_document_expiry_demotions();
    END IF;

    RETURN QUERY
    SELECT 
        COALESCE(array_length(affected_user_ids, 1), 0)::INTEGER,
        COALESCE(affected_user_ids, ARRAY[]::UUID[]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
