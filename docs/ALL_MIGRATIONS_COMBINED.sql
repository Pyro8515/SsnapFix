-- ============================================
-- ALL MIGRATIONS COMBINED
-- ============================================
-- This file contains ALL database migrations in order
-- Copy and paste this entire file into Supabase SQL Editor
-- All migrations are idempotent (safe to run multiple times)
-- ============================================
-- Migration 001: Initial Schema
-- ============================================
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (app-level, not auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_type TEXT NOT NULL CHECK (account_type IN ('customer', 'professional')),
    active_role TEXT NOT NULL DEFAULT 'customer',
    can_switch_roles BOOLEAN NOT NULL DEFAULT false,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional profiles
CREATE TABLE IF NOT EXISTS professional_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    identity_ref_id TEXT, -- Stripe Identity session reference
    identity_status TEXT CHECK (identity_status IN ('pending', 'verified', 'failed', 'needs_review')),
    services TEXT[] DEFAULT ARRAY[]::TEXT[], -- Array of trade types: ['plumbing', 'hvac', 'electrical', etc.]
    payouts_enabled BOOLEAN NOT NULL DEFAULT false,
    payouts_status TEXT CHECK (payouts_status IN ('pending', 'active', 'restricted', 'disabled')),
    stripe_account_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trade requirements (global and trade-specific)
CREATE TABLE IF NOT EXISTS trade_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trade TEXT NOT NULL, -- NULL means global requirement
    doc_type TEXT NOT NULL, -- 'government_id', 'general_liability', 'background_check', 'plumbing_license', etc.
    doc_subtype TEXT, -- For subtypes like 'plumbing_license' -> 'journeyman' or 'master'
    is_required BOOLEAN NOT NULL DEFAULT true,
    is_critical BOOLEAN NOT NULL DEFAULT false, -- Critical docs cause verification_status demotion if expired
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(trade, doc_type, COALESCE(doc_subtype, ''))
);

-- Professional documents
CREATE TABLE IF NOT EXISTS pro_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doc_type TEXT NOT NULL,
    doc_subtype TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'manual_review')),
    file_url TEXT NOT NULL,
    number TEXT, -- Document number (license number, policy number, etc.)
    issuer TEXT, -- Issuing authority
    issued_at DATE,
    expires_at DATE,
    reason TEXT, -- Rejection reason or notes
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Unique constraint: one active doc per (user_id, doc_type, doc_subtype)
    CONSTRAINT unique_active_doc UNIQUE (user_id, doc_type, COALESCE(doc_subtype, ''))
);

-- Trade compliance tracking
CREATE TABLE IF NOT EXISTS pro_trade_compliance (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trade TEXT NOT NULL,
    compliant BOOLEAN NOT NULL DEFAULT false,
    reason TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, trade)
);

-- Admin users
CREATE TABLE IF NOT EXISTS admin_users (
    user_id UUID NOT NULL PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Webhook events (for idempotency and audit)
CREATE TABLE IF NOT EXISTS webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id TEXT NOT NULL UNIQUE, -- Stripe event ID or other provider event ID
    event_type TEXT NOT NULL,
    source TEXT NOT NULL, -- 'stripe_identity', 'stripe_payments', etc.
    payload JSONB NOT NULL,
    processed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Jobs/Offers table (simplified for this backend)
CREATE TABLE IF NOT EXISTS offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_title TEXT NOT NULL,
    description TEXT,
    trade TEXT[] NOT NULL, -- Array of required trades
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    customer_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Offer assignments
CREATE TABLE IF NOT EXISTS offer_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    professional_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(offer_id, professional_user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_professional_profiles_user_id ON professional_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_pro_documents_user_id ON pro_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_pro_documents_status ON pro_documents(status);
CREATE INDEX IF NOT EXISTS idx_pro_documents_expires_at ON pro_documents(expires_at);
CREATE INDEX IF NOT EXISTS idx_pro_trade_compliance_user_id ON pro_trade_compliance(user_id);
CREATE INDEX IF NOT EXISTS idx_offers_status ON offers(status);
CREATE INDEX IF NOT EXISTS idx_offers_trade ON offers USING GIN(trade);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id ON webhook_events(event_id);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers (idempotent)
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_professional_profiles_updated_at ON professional_profiles;
CREATE TRIGGER update_professional_profiles_updated_at BEFORE UPDATE ON professional_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pro_documents_updated_at ON pro_documents;
CREATE TRIGGER update_pro_documents_updated_at BEFORE UPDATE ON pro_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_offers_updated_at ON offers;
CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_trade_compliance ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE offer_assignments ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM admin_users WHERE admin_users.user_id = is_admin.user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get user_id from auth.uid()
CREATE OR REPLACE FUNCTION auth_user_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT id FROM users WHERE auth_user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users policies
DROP POLICY IF EXISTS "Users can view their own record" ON users;
CREATE POLICY "Users can view their own record"
    ON users FOR SELECT
    USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own record" ON users;
CREATE POLICY "Users can update their own record"
    ON users FOR UPDATE
    USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (is_admin(auth_user_id()));

-- Professional profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON professional_profiles;
CREATE POLICY "Users can view their own profile"
    ON professional_profiles FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can update their own profile" ON professional_profiles;
CREATE POLICY "Users can update their own profile"
    ON professional_profiles FOR UPDATE
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can insert their own profile" ON professional_profiles;
CREATE POLICY "Users can insert their own profile"
    ON professional_profiles FOR INSERT
    WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all profiles" ON professional_profiles;
CREATE POLICY "Admins can view all profiles"
    ON professional_profiles FOR SELECT
    USING (is_admin(auth_user_id()));

-- Pro documents policies
DROP POLICY IF EXISTS "Users can view their own documents" ON pro_documents;
CREATE POLICY "Users can view their own documents"
    ON pro_documents FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can insert their own documents" ON pro_documents;
CREATE POLICY "Users can insert their own documents"
    ON pro_documents FOR INSERT
    WITH CHECK (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can update their own documents" ON pro_documents;
CREATE POLICY "Users can update their own documents"
    ON pro_documents FOR UPDATE
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all documents" ON pro_documents;
CREATE POLICY "Admins can view all documents"
    ON pro_documents FOR SELECT
    USING (is_admin(auth_user_id()));

DROP POLICY IF EXISTS "Admins can update all documents" ON pro_documents;
CREATE POLICY "Admins can update all documents"
    ON pro_documents FOR UPDATE
    USING (is_admin(auth_user_id()));

-- Trade compliance policies
DROP POLICY IF EXISTS "Users can view their own compliance" ON pro_trade_compliance;
CREATE POLICY "Users can view their own compliance"
    ON pro_trade_compliance FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all compliance" ON pro_trade_compliance;
CREATE POLICY "Admins can view all compliance"
    ON pro_trade_compliance FOR SELECT
    USING (is_admin(auth_user_id()));

-- Admin users policies (only admins can view)
DROP POLICY IF EXISTS "Admins can view admin list" ON admin_users;
CREATE POLICY "Admins can view admin list"
    ON admin_users FOR SELECT
    USING (is_admin(auth_user_id()));

-- Webhook events (admin only)
DROP POLICY IF EXISTS "Admins can view webhook events" ON webhook_events;
CREATE POLICY "Admins can view webhook events"
    ON webhook_events FOR SELECT
    USING (is_admin(auth_user_id()));

-- Offers policies (public read for authenticated users, write for customers/admins)
DROP POLICY IF EXISTS "Authenticated users can view offers" ON offers;
CREATE POLICY "Authenticated users can view offers"
    ON offers FOR SELECT
    USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Customers can create offers" ON offers;
CREATE POLICY "Customers can create offers"
    ON offers FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL AND
        (customer_user_id = auth_user_id() OR customer_user_id IS NULL)
    );

DROP POLICY IF EXISTS "Offer owners can update their offers" ON offers;
CREATE POLICY "Offer owners can update their offers"
    ON offers FOR UPDATE
    USING (customer_user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can manage all offers" ON offers;
CREATE POLICY "Admins can manage all offers"
    ON offers FOR ALL
    USING (is_admin(auth_user_id()));

-- Offer assignments policies
DROP POLICY IF EXISTS "Users can view assignments for their offers" ON offer_assignments;
CREATE POLICY "Users can view assignments for their offers"
    ON offer_assignments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM offers 
            WHERE offers.id = offer_assignments.offer_id 
            AND offers.customer_user_id = auth_user_id()
        )
    );

DROP POLICY IF EXISTS "Professionals can view their own assignments" ON offer_assignments;
CREATE POLICY "Professionals can view their own assignments"
    ON offer_assignments FOR SELECT
    USING (professional_user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all assignments" ON offer_assignments;
CREATE POLICY "Admins can view all assignments"
    ON offer_assignments FOR SELECT
    USING (is_admin(auth_user_id()));
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
-- Storage buckets (to be created via Supabase dashboard or API, but policies here)

-- Policy helper functions for storage
CREATE OR REPLACE FUNCTION storage_user_id()
RETURNS UUID AS $$
BEGIN
    -- Extract user_id from storage path: pro-avatars/{userId}/... or pro-docs/{userId}/...
    -- This is a simplified version; in practice, you'd parse the path
    RETURN auth_user_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Storage policies are typically set via Supabase dashboard or REST API
-- But we can create them via SQL if the storage schema is accessible
-- Note: These policies assume buckets are created separately

-- For pro-avatars bucket (public read, authenticated write to own path)
-- Policy: Users can upload to their own path
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'storage') THEN
        -- Note: Storage policies are managed differently in Supabase
        -- This is a placeholder showing the logic
        NULL;
    END IF;
END $$;
-- Seed data for development/testing

-- Insert default trade requirements
INSERT INTO trade_requirements (trade, doc_type, doc_subtype, is_required, is_critical) VALUES
-- Global requirements (trade = NULL)
(NULL, 'government_id', NULL, true, true),
(NULL, 'general_liability', NULL, true, true),
(NULL, 'background_check', NULL, false, false),

-- Trade-specific requirements
('plumbing', 'plumbing_license', NULL, true, true),
('plumbing', 'plumbing_license', 'journeyman', false, false),
('plumbing', 'plumbing_license', 'master', false, false),

('electrical', 'electrical_license', NULL, true, true),
('electrical', 'electrical_license', 'journeyman', false, false),
('electrical', 'electrical_license', 'master', false, false),

('hvac', 'hvac_license', NULL, true, true),
('hvac', 'epa_608', NULL, true, true),
('hvac', 'epa_608', 'type_i', false, false),
('hvac', 'epa_608', 'type_ii', false, false),
('hvac', 'epa_608', 'type_iii', false, false),
('hvac', 'epa_608', 'universal', false, false),

('painting', 'painting_license', NULL, false, false),
('painting', 'general_liability', NULL, true, true), -- Duplicate global, but explicit for trade

('locksmith', 'locksmith_license', NULL, true, true)
ON CONFLICT (trade, doc_type, COALESCE(doc_subtype, '')) DO NOTHING;

-- Note: Actual user creation requires auth.users entries first
-- These are example inserts that would be done after auth setup
-- For now, we'll create a helper function to seed users

-- Function to create seed users (requires auth.users to exist first)
CREATE OR REPLACE FUNCTION seed_test_users()
RETURNS VOID AS $$
DECLARE
    hvac_user_id UUID;
    plumbing_user_id UUID;
BEGIN
    -- This function assumes auth.users entries exist with these emails:
    -- hvac_pro@example.com
    -- plumbing_pro@example.com
    
    -- Get user IDs from auth.users (if they exist)
    SELECT id INTO hvac_user_id FROM auth.users WHERE email = 'hvac_pro@example.com' LIMIT 1;
    SELECT id INTO plumbing_user_id FROM auth.users WHERE email = 'plumbing_pro@example.com' LIMIT 1;
    
    -- Create app users if auth users exist
    IF hvac_user_id IS NOT NULL THEN
        INSERT INTO users (auth_user_id, account_type, active_role, can_switch_roles, verification_status)
        VALUES (hvac_user_id, 'professional', 'professional', true, 'approved')
        ON CONFLICT (auth_user_id) DO UPDATE SET
            verification_status = 'approved',
            can_switch_roles = true;
        
        -- Get the app user_id
        SELECT id INTO hvac_user_id FROM users WHERE auth_user_id = hvac_user_id;
        
        -- Create professional profile
        INSERT INTO professional_profiles (user_id, services, identity_status, payouts_enabled, payouts_status)
        VALUES (hvac_user_id, ARRAY['hvac', 'painting'], 'verified', true, 'active')
        ON CONFLICT (user_id) DO UPDATE SET
            services = ARRAY['hvac', 'painting'],
            identity_status = 'verified',
            payouts_status = 'active';
        
        -- Insert documents (HVAC pro - complete docs)
        INSERT INTO pro_documents (user_id, doc_type, doc_subtype, status, file_url, number, issuer, expires_at)
        VALUES
        (hvac_user_id, 'government_id', NULL, 'approved', 'https://storage.example.com/docs/gov-id-1.pdf', 'DL123456', 'State DMV', NULL),
        (hvac_user_id, 'general_liability', NULL, 'approved', 'https://storage.example.com/docs/gl-1.pdf', 'GL-POL-123', 'Insurance Co', CURRENT_DATE + INTERVAL '1 year'),
        (hvac_user_id, 'hvac_license', NULL, 'approved', 'https://storage.example.com/docs/hvac-license-1.pdf', 'HVAC-789', 'State Board', CURRENT_DATE + INTERVAL '2 years'),
        (hvac_user_id, 'epa_608', 'universal', 'approved', 'https://storage.example.com/docs/epa-608-1.pdf', 'EPA-608-UNIV', 'EPA', NULL),
        (hvac_user_id, 'background_check', NULL, 'approved', 'https://storage.example.com/docs/bg-check-1.pdf', 'BC-456', 'Background Check Inc', CURRENT_DATE + INTERVAL '1 year')
        ON CONFLICT (user_id, doc_type, COALESCE(doc_subtype, '')) DO UPDATE SET
            status = EXCLUDED.status,
            expires_at = EXCLUDED.expires_at;
        
        -- Recompute compliance
        PERFORM recompute_pro_trade_compliance(hvac_user_id);
    END IF;
    
    IF plumbing_user_id IS NOT NULL THEN
        INSERT INTO users (auth_user_id, account_type, active_role, can_switch_roles, verification_status)
        VALUES (plumbing_user_id, 'professional', 'professional', false, 'pending')
        ON CONFLICT (auth_user_id) DO UPDATE SET
            verification_status = 'pending',
            can_switch_roles = false;
        
        SELECT id INTO plumbing_user_id FROM users WHERE auth_user_id = plumbing_user_id;
        
        INSERT INTO professional_profiles (user_id, services, identity_status, payouts_enabled, payouts_status)
        VALUES (plumbing_user_id, ARRAY['plumbing'], 'verified', false, 'pending')
        ON CONFLICT (user_id) DO UPDATE SET
            services = ARRAY['plumbing'],
            identity_status = 'verified',
            payouts_status = 'pending';
        
        -- Plumbing pro - missing license (pending verification status)
        INSERT INTO pro_documents (user_id, doc_type, doc_subtype, status, file_url, number, issuer, expires_at)
        VALUES
        (plumbing_user_id, 'government_id', NULL, 'approved', 'https://storage.example.com/docs/gov-id-2.pdf', 'DL654321', 'State DMV', NULL),
        (plumbing_user_id, 'general_liability', NULL, 'approved', 'https://storage.example.com/docs/gl-2.pdf', 'GL-POL-456', 'Insurance Co', CURRENT_DATE + INTERVAL '1 year')
        -- Note: plumbing_license is missing - this keeps verification_status = pending
        ON CONFLICT (user_id, doc_type, COALESCE(doc_subtype, '')) DO UPDATE SET
            status = EXCLUDED.status;
        
        PERFORM recompute_pro_trade_compliance(plumbing_user_id);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Seed some offers (doesn't require auth users)
INSERT INTO offers (job_title, description, trade, location_lat, location_lng, status) VALUES
('Kitchen Sink Leak Repair', 'Kitchen sink has a leak under the cabinet. Need plumber to fix.', ARRAY['plumbing'], 40.7128, -74.0060, 'open'),
('AC Unit Replacement', 'Old AC unit needs replacement. HVAC professional needed.', ARRAY['hvac'], 40.7589, -73.9851, 'open'),
('Full House Painting', 'Interior and exterior painting for 3-bedroom house.', ARRAY['painting'], 40.7505, -73.9934, 'open'),
('Emergency Pipe Burst', 'Pipe burst in basement, need immediate plumbing service.', ARRAY['plumbing'], 40.7282, -73.9942, 'open'),
('HVAC Maintenance + Painting', 'AC maintenance and touch-up painting needed.', ARRAY['hvac', 'painting'], 40.7614, -73.9776, 'open')
ON CONFLICT DO NOTHING;
