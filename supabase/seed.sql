-- Comprehensive seed data for development/testing
-- This file can be run independently after migrations are applied
-- Note: Requires auth.users entries for test users (see seed_test_users function)

-- ============================================================================
-- TRADE REQUIREMENTS
-- ============================================================================
-- Insert default trade requirements (idempotent)
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

-- ============================================================================
-- SAMPLE OFFERS (No auth.users required)
-- ============================================================================
INSERT INTO offers (job_title, description, trade, location_lat, location_lng, status) VALUES
('Kitchen Sink Leak Repair', 'Kitchen sink has a leak under the cabinet. Need plumber to fix.', ARRAY['plumbing'], 40.7128, -74.0060, 'open'),
('AC Unit Replacement', 'Old AC unit needs replacement. HVAC professional needed.', ARRAY['hvac'], 40.7589, -73.9851, 'open'),
('Full House Painting', 'Interior and exterior painting for 3-bedroom house.', ARRAY['painting'], 40.7505, -73.9934, 'open'),
('Emergency Pipe Burst', 'Pipe burst in basement, need immediate plumbing service.', ARRAY['plumbing'], 40.7282, -73.9942, 'open'),
('HVAC Maintenance + Painting', 'AC maintenance and touch-up painting needed.', ARRAY['hvac', 'painting'], 40.7614, -73.9776, 'open'),
('Electrical Panel Upgrade', 'Need to upgrade 100A panel to 200A for new appliances.', ARRAY['electrical'], 40.7580, -73.9855, 'open'),
('Lock Installation', 'Need to install new locks on all doors after break-in.', ARRAY['locksmith'], 40.7549, -73.9840, 'open')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SEED TEST USERS FUNCTION
-- ============================================================================
-- Function to create seed users (requires auth.users to exist first)
-- Usage: SELECT seed_test_users();
-- This function creates:
-- 1. One approved professional (HVAC + Painting) with complete documents
-- 2. One pending professional (Plumbing) with missing required documents
CREATE OR REPLACE FUNCTION seed_test_users()
RETURNS TABLE(
    email TEXT,
    app_user_id UUID,
    verification_status TEXT,
    trades TEXT[]
) AS $$
DECLARE
    hvac_auth_id UUID;
    plumbing_auth_id UUID;
    hvac_app_user_id UUID;
    plumbing_app_user_id UUID;
BEGIN
    -- Get auth user IDs (if they exist)
    SELECT id INTO hvac_auth_id FROM auth.users WHERE email = 'hvac_pro@example.com' LIMIT 1;
    SELECT id INTO plumbing_auth_id FROM auth.users WHERE email = 'plumbing_pro@example.com' LIMIT 1;
    
    -- Create approved HVAC professional
    IF hvac_auth_id IS NOT NULL THEN
        -- Create app user
        INSERT INTO users (auth_user_id, account_type, active_role, can_switch_roles, verification_status)
        VALUES (hvac_auth_id, 'professional', 'professional', true, 'approved')
        ON CONFLICT (auth_user_id) DO UPDATE SET
            verification_status = 'approved',
            can_switch_roles = true,
            account_type = 'professional',
            active_role = 'professional';
        
        -- Get app user_id
        SELECT id INTO hvac_app_user_id FROM users WHERE auth_user_id = hvac_auth_id;
        
        -- Create professional profile
        INSERT INTO professional_profiles (user_id, services, identity_status, payouts_enabled, payouts_status)
        VALUES (hvac_app_user_id, ARRAY['hvac', 'painting'], 'verified', true, 'active')
        ON CONFLICT (user_id) DO UPDATE SET
            services = ARRAY['hvac', 'painting'],
            identity_status = 'verified',
            payouts_enabled = true,
            payouts_status = 'active';
        
        -- Insert documents (HVAC pro - complete docs)
        INSERT INTO pro_documents (user_id, doc_type, doc_subtype, status, file_url, number, issuer, expires_at)
        VALUES
        (hvac_app_user_id, 'government_id', NULL, 'approved', 'https://storage.example.com/docs/gov-id-1.pdf', 'DL123456', 'State DMV', NULL),
        (hvac_app_user_id, 'general_liability', NULL, 'approved', 'https://storage.example.com/docs/gl-1.pdf', 'GL-POL-123', 'Insurance Co', CURRENT_DATE + INTERVAL '1 year'),
        (hvac_app_user_id, 'hvac_license', NULL, 'approved', 'https://storage.example.com/docs/hvac-license-1.pdf', 'HVAC-789', 'State Board', CURRENT_DATE + INTERVAL '2 years'),
        (hvac_app_user_id, 'epa_608', 'universal', 'approved', 'https://storage.example.com/docs/epa-608-1.pdf', 'EPA-608-UNIV', 'EPA', NULL),
        (hvac_app_user_id, 'background_check', NULL, 'approved', 'https://storage.example.com/docs/bg-check-1.pdf', 'BC-456', 'Background Check Inc', CURRENT_DATE + INTERVAL '1 year')
        ON CONFLICT (user_id, doc_type, COALESCE(doc_subtype, '')) DO UPDATE SET
            status = EXCLUDED.status,
            expires_at = EXCLUDED.expires_at,
            file_url = EXCLUDED.file_url,
            number = EXCLUDED.number,
            issuer = EXCLUDED.issuer;
        
        -- Recompute compliance
        PERFORM recompute_pro_trade_compliance(hvac_app_user_id);
        
        RETURN QUERY SELECT 'hvac_pro@example.com'::TEXT, hvac_app_user_id, 'approved'::TEXT, ARRAY['hvac', 'painting']::TEXT[];
    END IF;
    
    -- Create pending plumbing professional
    IF plumbing_auth_id IS NOT NULL THEN
        -- Create app user
        INSERT INTO users (auth_user_id, account_type, active_role, can_switch_roles, verification_status)
        VALUES (plumbing_auth_id, 'professional', 'professional', false, 'pending')
        ON CONFLICT (auth_user_id) DO UPDATE SET
            verification_status = 'pending',
            can_switch_roles = false,
            account_type = 'professional',
            active_role = 'professional';
        
        -- Get app user_id
        SELECT id INTO plumbing_app_user_id FROM users WHERE auth_user_id = plumbing_auth_id;
        
        -- Create professional profile
        INSERT INTO professional_profiles (user_id, services, identity_status, payouts_enabled, payouts_status)
        VALUES (plumbing_app_user_id, ARRAY['plumbing'], 'verified', false, 'pending')
        ON CONFLICT (user_id) DO UPDATE SET
            services = ARRAY['plumbing'],
            identity_status = 'verified',
            payouts_enabled = false,
            payouts_status = 'pending';
        
        -- Plumbing pro - missing license (pending verification status)
        INSERT INTO pro_documents (user_id, doc_type, doc_subtype, status, file_url, number, issuer, expires_at)
        VALUES
        (plumbing_app_user_id, 'government_id', NULL, 'approved', 'https://storage.example.com/docs/gov-id-2.pdf', 'DL654321', 'State DMV', NULL),
        (plumbing_app_user_id, 'general_liability', NULL, 'approved', 'https://storage.example.com/docs/gl-2.pdf', 'GL-POL-456', 'Insurance Co', CURRENT_DATE + INTERVAL '1 year')
        -- Note: plumbing_license is missing - this keeps verification_status = pending
        ON CONFLICT (user_id, doc_type, COALESCE(doc_subtype, '')) DO UPDATE SET
            status = EXCLUDED.status,
            expires_at = EXCLUDED.expires_at,
            file_url = EXCLUDED.file_url,
            number = EXCLUDED.number,
            issuer = EXCLUDED.issuer;
        
        -- Recompute compliance
        PERFORM recompute_pro_trade_compliance(plumbing_app_user_id);
        
        RETURN QUERY SELECT 'plumbing_pro@example.com'::TEXT, plumbing_app_user_id, 'pending'::TEXT, ARRAY['plumbing']::TEXT[];
    END IF;
    
    -- Return empty result if no users found
    IF hvac_auth_id IS NULL AND plumbing_auth_id IS NULL THEN
        RETURN QUERY SELECT NULL::TEXT, NULL::UUID, NULL::TEXT, NULL::TEXT[];
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- NOTES
-- ============================================================================
-- To use seed_test_users():
-- 1. Create auth.users entries first via Supabase Auth API or Dashboard:
--    - hvac_pro@example.com (password: any)
--    - plumbing_pro@example.com (password: any)
-- 2. Run: SELECT * FROM seed_test_users();
-- 
-- The function will:
-- - Create app users with proper account_type and roles
-- - Create professional profiles with services
-- - Insert documents (approved pro has all docs, pending pro is missing license)
-- - Recompute trade compliance
-- - Return a summary of created users

