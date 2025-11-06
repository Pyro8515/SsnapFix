-- ============================================
-- COMPLETE DATABASE SCHEMA
-- ============================================
-- This file contains the complete database schema for GetDone
-- Copy and paste this entire file into Supabase SQL Editor
-- All statements are idempotent (safe to re-run)
-- ============================================

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- ENUM TYPES
-- ============================================

DO $$ BEGIN
    CREATE TYPE account_type AS ENUM ('customer', 'professional');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE role_type AS ENUM ('customer', 'professional');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE doc_status AS ENUM ('pending', 'approved', 'rejected', 'expired', 'manual_review');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_status AS ENUM ('draft', 'requested', 'assigned', 'en_route', 'arrived', 'in_progress', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE offer_status AS ENUM ('offered', 'accepted', 'declined', 'expired', 'withdrawn');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type AS ENUM ('hold', 'charge', 'payout', 'refund', 'adjustment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABLES
-- ============================================

-- Users table (app table; not auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    account_type account_type NOT NULL DEFAULT 'customer',
    active_role role_type NOT NULL DEFAULT 'customer',
    can_switch_roles BOOLEAN NOT NULL DEFAULT false,
    verification_status verification_status NOT NULL DEFAULT 'pending',
    avatar_url TEXT,
    full_name TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_account_type CHECK (account_type IN ('customer', 'professional'))
);

-- Customer profiles
CREATE TABLE IF NOT EXISTS public.customer_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    default_address JSONB,
    saved_addresses JSONB,
    preferences JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional profiles
CREATE TABLE IF NOT EXISTS public.professional_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    bio TEXT,
    services TEXT[],
    experience_years SMALLINT,
    address TEXT,
    zip_code TEXT,
    available_days TEXT[],
    emergency_calls BOOLEAN NOT NULL DEFAULT false,
    working_hours JSONB DEFAULT '{"start":"08:00","end":"18:00"}'::JSONB,
    service_area_km NUMERIC DEFAULT 25,
    base_location GEOGRAPHY(Point,4326),
    is_online BOOLEAN NOT NULL DEFAULT false,
    current_location GEOGRAPHY(Point,4326),
    rating_average NUMERIC(3,2) DEFAULT 0.00,
    rating_count INTEGER DEFAULT 0,
    identity_provider TEXT,
    identity_ref_id TEXT,
    identity_status TEXT,
    payouts_status TEXT,
    connect_account_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Services (master list)
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    base_price_cents INTEGER DEFAULT 0,
    diagnostic_fee_cents INTEGER DEFAULT 7900,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trade requirements
CREATE TABLE IF NOT EXISTS public.trade_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_code TEXT NOT NULL REFERENCES public.services(code) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    subtype TEXT,
    is_global BOOLEAN NOT NULL DEFAULT false,
    is_optional BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional documents
CREATE TABLE IF NOT EXISTS public.pro_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    doc_type TEXT NOT NULL,
    doc_subtype TEXT,
    status doc_status NOT NULL DEFAULT 'pending',
    file_url TEXT NOT NULL,
    number TEXT,
    issuer TEXT,
    issued_at DATE,
    expires_at DATE,
    reason TEXT,
    meta JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional document audits
CREATE TABLE IF NOT EXISTS public.pro_document_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doc_id UUID NOT NULL REFERENCES public.pro_documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional trade compliance
CREATE TABLE IF NOT EXISTS public.pro_trade_compliance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    service_code TEXT NOT NULL REFERENCES public.services(code) ON DELETE CASCADE,
    compliant BOOLEAN NOT NULL DEFAULT false,
    reason TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, service_code)
);

-- Availability
CREATE TABLE IF NOT EXISTS public.availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_local TIME NOT NULL,
    end_local TIME NOT NULL,
    effective_from DATE,
    effective_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organizations
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organization members
CREATE TABLE IF NOT EXISTS public.org_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(org_id, user_id)
);

-- Jobs
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_pro_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    service_code TEXT NOT NULL REFERENCES public.services(code),
    status job_status NOT NULL DEFAULT 'requested',
    address JSONB NOT NULL,
    location GEOGRAPHY(Point,4326),
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    price_cents INTEGER NOT NULL DEFAULT 0,
    platform_fee_cents INTEGER DEFAULT 0,
    payout_cents INTEGER DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_intent_id TEXT,
    payment_status TEXT DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Job events
CREATE TABLE IF NOT EXISTS public.job_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    actor_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    event TEXT NOT NULL,
    location GEOGRAPHY(Point,4326),
    meta JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Job offers
CREATE TABLE IF NOT EXISTS public.job_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    pro_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status offer_status NOT NULL DEFAULT 'offered',
    expires_at TIMESTAMPTZ,
    distance_km NUMERIC,
    payout_cents INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(job_id, pro_user_id)
);

-- Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type transaction_type NOT NULL,
    amount_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    external_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Role switches
CREATE TABLE IF NOT EXISTS public.role_switches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    from_role role_type NOT NULL,
    to_role role_type NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Admin users
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Webhook events
CREATE TABLE IF NOT EXISTS public.webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider TEXT NOT NULL,
    event_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    handled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider, event_id)
);

-- Ratings
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    pro_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(job_id, customer_id)
);

-- ============================================
-- INDEXES
-- ============================================

-- Users
CREATE INDEX IF NOT EXISTS idx_users_active_role ON public.users(active_role);

-- Professional profiles
CREATE INDEX IF NOT EXISTS idx_professional_profiles_services ON public.professional_profiles USING GIN(services);
CREATE INDEX IF NOT EXISTS idx_professional_profiles_base_location ON public.professional_profiles USING GIST(base_location);
CREATE INDEX IF NOT EXISTS idx_professional_profiles_current_location ON public.professional_profiles USING GIST(current_location);
CREATE INDEX IF NOT EXISTS idx_professional_profiles_is_online ON public.professional_profiles(is_online);
-- Note: available_days validation should be done at application level
-- PostgreSQL CHECK constraints cannot use subqueries

-- Trade requirements
CREATE UNIQUE INDEX IF NOT EXISTS idx_trade_requirements_unique ON public.trade_requirements(service_code, kind, COALESCE(subtype, ''));

-- Pro documents
CREATE INDEX IF NOT EXISTS idx_pro_documents_user_status ON public.pro_documents(user_id, status);
CREATE INDEX IF NOT EXISTS idx_pro_documents_expires_at ON public.pro_documents(expires_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pro_documents_active_unique ON public.pro_documents(user_id, doc_type, COALESCE(doc_subtype, ''))
    WHERE status IN ('pending', 'approved', 'manual_review');

-- Pro document audits
CREATE INDEX IF NOT EXISTS idx_pro_document_audits_doc_created ON public.pro_document_audits(doc_id, created_at DESC);

-- Availability
CREATE INDEX IF NOT EXISTS idx_availability_user_day ON public.availability(user_id, day_of_week);

-- Jobs
CREATE INDEX IF NOT EXISTS idx_jobs_customer ON public.jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_pro ON public.jobs(assigned_pro_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_address ON public.jobs USING GIN(address);
CREATE INDEX IF NOT EXISTS idx_jobs_location ON public.jobs USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_jobs_service_status ON public.jobs(service_code, status);

-- Ratings
CREATE INDEX IF NOT EXISTS idx_ratings_pro ON public.ratings(pro_user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_job ON public.ratings(job_id);
CREATE INDEX IF NOT EXISTS idx_ratings_created ON public.ratings(created_at DESC);

-- Job events
CREATE INDEX IF NOT EXISTS idx_job_events_job_created ON public.job_events(job_id, created_at);
CREATE INDEX IF NOT EXISTS idx_job_events_location ON public.job_events USING GIST(location);

-- Job offers
CREATE INDEX IF NOT EXISTS idx_job_offers_pro_status ON public.job_offers(pro_user_id, status);

-- Transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON public.transactions(user_id, created_at DESC);

-- Role switches
CREATE INDEX IF NOT EXISTS idx_role_switches_user_created ON public.role_switches(user_id, created_at DESC);

-- ============================================
-- VIEWS
-- ============================================

-- View: v_user_active_docs
CREATE OR REPLACE VIEW public.v_user_active_docs AS
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
    meta,
    created_at,
    updated_at
FROM public.pro_documents
WHERE status IN ('approved', 'pending', 'manual_review', 'rejected', 'expired')
ORDER BY 
    user_id, 
    doc_type, 
    COALESCE(doc_subtype, ''),
    CASE status
        WHEN 'approved' THEN 1
        WHEN 'pending' THEN 2
        WHEN 'manual_review' THEN 3
        WHEN 'rejected' THEN 4
        WHEN 'expired' THEN 5
    END,
    updated_at DESC;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: update_pro_rating_after_rating_change
CREATE OR REPLACE FUNCTION public.update_pro_rating_after_rating_change()
RETURNS TRIGGER AS $$
DECLARE
    affected_pro_id UUID;
BEGIN
    -- Get pro_user_id from the affected row
    IF TG_OP = 'DELETE' THEN
        affected_pro_id := OLD.pro_user_id;
    ELSE
        affected_pro_id := NEW.pro_user_id;
    END IF;

    -- Update professional profile with new rating stats
    UPDATE public.professional_profiles
    SET
        rating_count = (
            SELECT COUNT(*) FROM public.ratings
            WHERE pro_user_id = affected_pro_id
        ),
        rating_average = (
            SELECT COALESCE(ROUND(AVG(rating)::numeric, 2), 0) FROM public.ratings
            WHERE pro_user_id = affected_pro_id
        ),
        updated_at = NOW()
    WHERE user_id = affected_pro_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_pro_rating ON public.ratings;
CREATE TRIGGER trigger_update_pro_rating
    AFTER INSERT OR UPDATE OR DELETE ON public.ratings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_pro_rating_after_rating_change();

-- Function: recompute_pro_trade_compliance
CREATE OR REPLACE FUNCTION public.recompute_pro_trade_compliance(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
    user_services TEXT[];
    service_item TEXT;
    required_req RECORD;
    user_doc_exists BOOLEAN;
    all_compliant BOOLEAN;
    missing_docs TEXT[];
    compliance_reason TEXT;
    identity_approved BOOLEAN;
    global_critical_missing BOOLEAN;
    user_verification_status verification_status;
BEGIN
    -- Get user's services from professional_profiles
    SELECT COALESCE(services, ARRAY[]::TEXT[]) INTO user_services
    FROM public.professional_profiles
    WHERE user_id = target_user_id;

    -- Check identity status
    SELECT 
        CASE 
            WHEN identity_status = 'verified' THEN true 
            ELSE false 
        END
    INTO identity_approved
    FROM public.professional_profiles
    WHERE user_id = target_user_id;

    -- If no services, clear compliance records
    IF user_services IS NULL OR array_length(user_services, 1) IS NULL THEN
        DELETE FROM public.pro_trade_compliance WHERE user_id = target_user_id;
        RETURN;
    END IF;

    -- Check compliance for each service
    FOREACH service_item IN ARRAY user_services
    LOOP
        all_compliant := true;
        missing_docs := ARRAY[]::TEXT[];
        global_critical_missing := false;

        -- Check global requirements first
        FOR required_req IN
            SELECT kind, subtype, is_optional
            FROM public.trade_requirements
            WHERE is_global = true
            AND is_optional = false
        LOOP
            -- Check if user has this document in approved/pending status and not expired
            SELECT EXISTS (
                SELECT 1 FROM public.v_user_active_docs
                WHERE user_id = target_user_id
                AND doc_type = required_req.kind
                AND COALESCE(doc_subtype, '') = COALESCE(required_req.subtype, '')
                AND status = 'approved'
                AND (expires_at IS NULL OR expires_at > CURRENT_DATE)
            ) INTO user_doc_exists;

            IF NOT user_doc_exists THEN
                all_compliant := false;
                global_critical_missing := true;
                missing_docs := array_append(
                    missing_docs,
                    required_req.kind || 
                    CASE WHEN required_req.subtype IS NOT NULL THEN ' (' || required_req.subtype || ')' ELSE '' END ||
                    ' (global)'
                );
            END IF;
        END LOOP;

        -- Check service-specific requirements
        FOR required_req IN
            SELECT kind, subtype, is_optional
            FROM public.trade_requirements
            WHERE service_code = service_item
            AND is_global = false
            AND is_optional = false
        LOOP
            SELECT EXISTS (
                SELECT 1 FROM public.v_user_active_docs
                WHERE user_id = target_user_id
                AND doc_type = required_req.kind
                AND COALESCE(doc_subtype, '') = COALESCE(required_req.subtype, '')
                AND status = 'approved'
                AND (expires_at IS NULL OR expires_at > CURRENT_DATE)
            ) INTO user_doc_exists;

            IF NOT user_doc_exists THEN
                all_compliant := false;
                missing_docs := array_append(
                    missing_docs,
                    required_req.kind || 
                    CASE WHEN required_req.subtype IS NOT NULL THEN ' (' || required_req.subtype || ')' ELSE '' END
                );
            END IF;
        END LOOP;

        -- Special handling for government_id: must be verified via Stripe Identity
        IF EXISTS (
            SELECT 1 FROM public.trade_requirements
            WHERE (is_global = true OR service_code = service_item)
            AND kind = 'government_id'
            AND is_optional = false
        ) THEN
            IF NOT identity_approved THEN
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
        INSERT INTO public.pro_trade_compliance (user_id, service_code, compliant, reason, updated_at)
        VALUES (target_user_id, service_item, all_compliant, compliance_reason, NOW())
        ON CONFLICT (user_id, service_code)
        DO UPDATE SET
            compliant = EXCLUDED.compliant,
            reason = EXCLUDED.reason,
            updated_at = NOW();
    END LOOP;

    -- Update users.verification_status
    -- approved iff identity approved and at least one selected service compliant and no critical global doc is missing
    SELECT 
        CASE 
            WHEN identity_approved = true 
                AND EXISTS (
                    SELECT 1 FROM public.pro_trade_compliance
                    WHERE user_id = target_user_id
                    AND compliant = true
                )
                AND NOT global_critical_missing
            THEN 'approved'::verification_status
            ELSE 'pending'::verification_status
        END
    INTO user_verification_status;

    UPDATE public.users
    SET verification_status = user_verification_status
    WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger function: update_updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables with updated_at column
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND column_name = 'updated_at'
        AND table_name IN (
            'users', 'customer_profiles', 'professional_profiles', 'services',
            'trade_requirements', 'pro_documents', 'availability', 'organizations',
            'org_members', 'jobs', 'job_offers', 'transactions', 'ratings'
        )
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_updated_at ON public.%I;
            CREATE TRIGGER update_%I_updated_at
                BEFORE UPDATE ON public.%I
                FOR EACH ROW
                EXECUTE FUNCTION public.update_updated_at_column();
        ', tbl.table_name, tbl.table_name, tbl.table_name, tbl.table_name);
    END LOOP;
END $$;

-- Trigger: recompute on doc changes
CREATE OR REPLACE FUNCTION public.trigger_recompute_compliance_on_doc_change()
RETURNS TRIGGER AS $$
DECLARE
    affected_user_id UUID;
BEGIN
    -- Get user_id from the affected row
    IF TG_OP = 'DELETE' THEN
        affected_user_id := OLD.user_id;
    ELSE
        affected_user_id := NEW.user_id;
    END IF;

    -- Recompute compliance
    PERFORM public.recompute_pro_trade_compliance(affected_user_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_recompute_compliance_on_doc_change ON public.pro_documents;
CREATE TRIGGER trigger_recompute_compliance_on_doc_change
    AFTER INSERT OR UPDATE OR DELETE ON public.pro_documents
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_recompute_compliance_on_doc_change();

-- ============================================
-- SEED DATA
-- ============================================

-- Seed services with pricing
INSERT INTO public.services (code, name, description, base_price_cents, diagnostic_fee_cents, is_active) VALUES
    ('plumbing', 'Plumbing', 'Plumbing repairs and installations', 15000, 7900, true),
    ('electrical', 'Electrical', 'Electrical repairs and installations', 18000, 7900, true),
    ('hvac', 'HVAC', 'Heating, ventilation, and air conditioning', 20000, 7900, true),
    ('locksmith', 'Locksmith', 'Locksmith services', 12000, 7900, true),
    ('handyman', 'Handyman', 'General handyman services', 10000, 7900, true),
    ('cleaning', 'Cleaning', 'Cleaning services', 8000, 7900, true),
    ('landscaping', 'Landscaping', 'Landscaping and lawn care', 12000, 7900, true),
    ('painting', 'Painting', 'Painting services', 14000, 7900, true)
ON CONFLICT (code) DO UPDATE SET
    base_price_cents = EXCLUDED.base_price_cents,
    diagnostic_fee_cents = EXCLUDED.diagnostic_fee_cents;

-- Seed trade requirements
-- Note: Global requirements reference 'plumbing' as placeholder since service_code is NOT NULL
-- The is_global flag indicates they apply to all services (query logic checks is_global=true)
INSERT INTO public.trade_requirements (service_code, kind, subtype, is_global, is_optional) VALUES
    -- Global requirements (use 'plumbing' as placeholder service_code, is_global=true means applies to all)
    ('plumbing', 'insurance_general', NULL, true, false),
    ('plumbing', 'background_check', NULL, true, true),
    -- Plumbing-specific
    ('plumbing', 'license', 'state', false, false),
    -- Electrical-specific
    ('electrical', 'license', 'state', false, false),
    -- HVAC-specific
    ('hvac', 'license', 'state', false, false),
    ('hvac', 'epa_608', NULL, false, false),
    -- Locksmith-specific
    ('locksmith', 'license', 'state', false, false)
ON CONFLICT DO NOTHING;

-- ============================================
-- RLS POLICIES (COMMENTS ONLY - NOT ENABLED)
-- ============================================

/*
-- RLS Policies (to be applied later via separate migration)

-- Users
-- Policy: owner can select/update own row
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);
-- Policy: admin can select/update all
CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));
CREATE POLICY "Admins can update all users" ON public.users
    FOR UPDATE USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

-- Customer profiles
-- Policy: owner RW, admin RW
CREATE POLICY "Users can manage own customer profile" ON public.customer_profiles
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all customer profiles" ON public.customer_profiles
    FOR ALL USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

-- Professional profiles
-- Policy: owner RW, admin RW
CREATE POLICY "Users can manage own professional profile" ON public.professional_profiles
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all professional profiles" ON public.professional_profiles
    FOR ALL USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

-- Pro documents
-- Policy: owner RW; admin RW; others no read
CREATE POLICY "Users can manage own documents" ON public.pro_documents
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all documents" ON public.pro_documents
    FOR ALL USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

-- Pro document audits
-- Policy: owner R (their docs only); admin R
CREATE POLICY "Users can view own document audits" ON public.pro_document_audits
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.pro_documents
            WHERE id = pro_document_audits.doc_id
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Admins can view all document audits" ON public.pro_document_audits
    FOR SELECT USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

-- Jobs / Job offers / Job events
-- Policy: customer can read own; assigned pro can read; admin RW
CREATE POLICY "Customers can manage own jobs" ON public.jobs
    FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Assigned pros can view assigned jobs" ON public.jobs
    FOR SELECT USING (auth.uid() = assigned_pro_id);
CREATE POLICY "Admins can manage all jobs" ON public.jobs
    FOR ALL USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()));

CREATE POLICY "Users can view related job offers" ON public.job_offers
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.jobs WHERE id = job_offers.job_id AND customer_id = auth.uid())
        OR pro_user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can view related job events" ON public.job_events
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.jobs WHERE id = job_events.job_id AND (customer_id = auth.uid() OR assigned_pro_id = auth.uid()))
        OR EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
    );

-- Storage bucket policies (to be applied via storage.objects policies)
-- pro-avatars: public read, owner write
-- pro-docs: private, owner read/write, admin read/write
*/

-- ============================================
-- END OF SCHEMA
-- ============================================

