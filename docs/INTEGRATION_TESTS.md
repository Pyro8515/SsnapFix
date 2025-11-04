# Integration Tests

This document describes the integration tests that should be implemented to verify the backend functionality.

## Test Scenarios

### 1. Union/Dedupe Requirements

**Test**: Verify that when a user has multiple trades, requirements are properly unioned and deduplicated.

**Setup**:
- User has trades: ['hvac', 'painting']
- Trade requirements:
  - Global: 'general_liability' (required)
  - HVAC: 'hvac_license' (required), 'epa_608' (required)
  - Painting: 'general_liability' (required) - duplicate of global

**Expected**:
- `recompute_pro_trade_compliance` should only require one 'general_liability' document
- User should be compliant for both trades if they have: general_liability, hvac_license, epa_608

**Test Query**:
```sql
-- Setup test user with multiple trades
INSERT INTO users (auth_user_id, account_type, active_role) 
VALUES ('test-auth-user-id', 'professional', 'professional');

-- Insert profile with multiple trades
INSERT INTO professional_profiles (user_id, services) 
VALUES ('test-user-id', ARRAY['hvac', 'painting']);

-- Insert required documents
INSERT INTO pro_documents (user_id, doc_type, status, file_url, expires_at)
VALUES 
  ('test-user-id', 'general_liability', 'approved', 'http://example.com/gl.pdf', CURRENT_DATE + INTERVAL '1 year'),
  ('test-user-id', 'hvac_license', 'approved', 'http://example.com/hvac.pdf', CURRENT_DATE + INTERVAL '1 year'),
  ('test-user-id', 'epa_608', 'approved', 'http://example.com/epa.pdf', NULL);

-- Recompute compliance
SELECT recompute_pro_trade_compliance('test-user-id');

-- Verify both trades are compliant
SELECT trade, compliant FROM pro_trade_compliance WHERE user_id = 'test-user-id';
-- Expected: hvac=true, painting=true
```

### 2. Accept Job Gating + 409 Reasons

**Test**: Verify that accepting a job returns 409 with reasons when compliance issues exist.

**Setup**:
- User has trade 'plumbing' but is NOT compliant
- Offer requires trade 'plumbing'

**Expected**:
- POST /api/pro/offers/accept returns 409
- Response includes `reasons` array with human-readable messages

**Test Flow**:
1. Create user with plumbing trade but missing required documents
2. Create offer requiring plumbing
3. Call POST /api/pro/offers/accept
4. Verify 409 response with reasons

### 3. Identity Webhook Idempotency

**Test**: Verify that processing the same Stripe Identity webhook event twice doesn't duplicate state changes.

**Setup**:
- Stripe sends verification event with ID 'evt_test_123'

**Expected**:
- First webhook call: processes event, updates profile, logs to webhook_events
- Second webhook call: returns 200 but doesn't reprocess (idempotent)

**Test Flow**:
1. Send webhook event with `identity.verification_session.verified`
2. Verify profile updated and webhook_events.processed = true
3. Send same event again
4. Verify no duplicate updates

### 4. Expiry Demotion Path

**Test**: Verify that when critical documents expire, verification_status is demoted to 'pending'.

**Setup**:
- User has verification_status = 'approved'
- User has critical global doc 'general_liability' that expires today

**Expected**:
- After running `expire_pro_documents()`, document status = 'expired'
- User verification_status = 'pending'
- Compliance recomputed

**Test Query**:
```sql
-- Setup user with approved status and expiring critical doc
UPDATE users SET verification_status = 'approved' WHERE id = 'test-user-id';
UPDATE pro_documents 
SET expires_at = CURRENT_DATE - INTERVAL '1 day'
WHERE user_id = 'test-user-id' AND doc_type = 'general_liability';

-- Run expiry function
SELECT * FROM expire_pro_documents();

-- Verify status changed
SELECT verification_status FROM users WHERE id = 'test-user-id';
-- Expected: 'pending'

SELECT status FROM pro_documents 
WHERE user_id = 'test-user-id' AND doc_type = 'general_liability';
-- Expected: 'expired'
```

## Test Data Setup

Create a test helper script:

```sql
-- Create test users (requires auth.users entries first)
CREATE OR REPLACE FUNCTION setup_test_user(
  auth_id UUID,
  account_type_param TEXT,
  services_param TEXT[] DEFAULT ARRAY[]::TEXT[]
)
RETURNS UUID AS $$
DECLARE
  app_user_id UUID;
BEGIN
  -- Create app user
  INSERT INTO users (auth_user_id, account_type, active_role)
  VALUES (auth_id, account_type_param, account_type_param)
  ON CONFLICT (auth_user_id) DO UPDATE SET account_type = account_type_param
  RETURNING id INTO app_user_id;

  -- Create professional profile if needed
  IF account_type_param = 'professional' THEN
    INSERT INTO professional_profiles (user_id, services)
    VALUES (app_user_id, services_param)
    ON CONFLICT (user_id) DO UPDATE SET services = services_param;
  END IF;

  RETURN app_user_id;
END;
$$ LANGUAGE plpgsql;
```

## Running Tests

### Manual Testing

1. Set up test environment with seed data
2. Run SQL test queries
3. Use Postman collection to test API endpoints
4. Verify responses match expected behavior

### Automated Testing (Future)

Consider implementing automated tests using:
- Postman Newman (for API tests)
- pgTAP (for SQL function tests)
- Jest/Mocha (for Edge Function unit tests)
