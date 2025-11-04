-- Migration: Auto-recompute triggers for compliance
-- Triggers recompute_pro_trade_compliance on:
-- 1. Document status changes (approve/reject/expire)
-- 2. Professional profile services array changes

-- Function to trigger recompute on document status changes
CREATE OR REPLACE FUNCTION trigger_recompute_on_doc_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only recompute if status actually changed
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        -- Recompute compliance for the affected user
        PERFORM recompute_pro_trade_compliance(NEW.user_id);
    ELSIF TG_OP = 'INSERT' THEN
        -- Recompute on new document submission
        PERFORM recompute_pro_trade_compliance(NEW.user_id);
    ELSIF TG_OP = 'DELETE' THEN
        -- Recompute when document is deleted
        PERFORM recompute_pro_trade_compliance(OLD.user_id);
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on pro_documents for status changes
DROP TRIGGER IF EXISTS trigger_recompute_on_doc_status_change ON pro_documents;
CREATE TRIGGER trigger_recompute_on_doc_status_change
    AFTER INSERT OR UPDATE OF status OR DELETE ON pro_documents
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recompute_on_doc_status_change();

-- Function to trigger recompute on professional profile services change
CREATE OR REPLACE FUNCTION trigger_recompute_on_services_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only recompute if services array actually changed
    IF TG_OP = 'UPDATE' THEN
        -- Check if services array changed
        IF OLD.services IS DISTINCT FROM NEW.services THEN
            PERFORM recompute_pro_trade_compliance(NEW.user_id);
        END IF;
    ELSIF TG_OP = 'INSERT' THEN
        -- Recompute on new profile creation
        PERFORM recompute_pro_trade_compliance(NEW.user_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on professional_profiles for services changes
DROP TRIGGER IF EXISTS trigger_recompute_on_services_change ON professional_profiles;
CREATE TRIGGER trigger_recompute_on_services_change
    AFTER INSERT OR UPDATE OF services ON professional_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recompute_on_services_change();

-- Function to trigger recompute on identity status change
-- This is already handled in the webhook, but adding trigger for completeness
CREATE OR REPLACE FUNCTION trigger_recompute_on_identity_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only recompute if identity_status actually changed
    IF TG_OP = 'UPDATE' AND OLD.identity_status IS DISTINCT FROM NEW.identity_status THEN
        PERFORM recompute_pro_trade_compliance(NEW.user_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on professional_profiles for identity_status changes
DROP TRIGGER IF EXISTS trigger_recompute_on_identity_status_change ON professional_profiles;
CREATE TRIGGER trigger_recompute_on_identity_status_change
    AFTER UPDATE OF identity_status ON professional_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recompute_on_identity_status_change();

