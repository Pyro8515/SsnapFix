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
