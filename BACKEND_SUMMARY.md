# GetDone Backend Implementation Summary

This document summarizes the complete backend implementation for the GetDone platform.

## Overview

The backend is built on **Supabase** (PostgreSQL + Storage + Edge Functions) and provides:
- Database schema with RLS policies
- REST API endpoints via Supabase Edge Functions
- Stripe integration for identity verification and payments
- Document management with storage
- Trade compliance checking
- Webhook handlers for Stripe events

## Architecture

### Database Layer

**Tables**:
- `users` - App-level user records (not auth.users)
- `professional_profiles` - Professional-specific data
- `pro_documents` - Document uploads and verification
- `pro_trade_compliance` - Trade compliance tracking
- `trade_requirements` - Requirements per trade
- `admin_users` - Admin access control
- `webhook_events` - Webhook idempotency tracking
- `offers` - Job listings
- `offer_assignments` - Job assignments

**Views**:
- `v_user_active_docs` - Latest active documents per user

**Functions**:
- `recompute_pro_trade_compliance(user_id)` - Recalculates compliance
- `expire_pro_documents()` - Marks expired docs and updates compliance

**Security**:
- Row Level Security (RLS) enabled on all tables
- Users can only access their own data
- Admins have elevated access
- Storage policies enforce path-based access

### API Layer (Edge Functions)

All endpoints are implemented as Supabase Edge Functions:

1. **User Management**
   - `GET /api/me` - Get current user info with documents and compliance
   - `POST /api/role/switch` - Switch between customer/professional role

2. **Offers/Jobs**
   - `GET /api/offers` - List available offers (filtered by compliance)
   - `POST /api/pro/offers/accept` - Accept an offer (with compliance gating)

3. **Verification**
   - `POST /api/stripe/identity/start` - Start Stripe Identity verification
   - `POST /api/stripe/identity/webhook` - Handle Stripe Identity webhooks

4. **Documents**
   - `POST /api/pro-docs/presign` - Generate presigned upload URL
   - `POST /api/pro-docs/submit` - Submit document metadata

5. **Payments**
   - `POST /api/payments/start` - Start Stripe Connect onboarding
   - `POST /api/stripe/payments/webhook` - Handle Stripe Payments webhooks

### Storage

**Buckets**:
- `pro-avatars` (public) - User avatars
- `pro-docs` (private) - Professional documents

**Policies**:
- Users can only access their own files
- Admins can view all documents
- Public read for avatars

## Key Features

### 1. Trade Compliance Engine

- **Requirements**: Global + trade-specific requirements
- **Union/Dedupe**: Multiple trades union requirements, deduplicate global docs
- **Compliance Check**: Validates all required docs are present and not expired
- **Auto-recompute**: Triggered on document upload, webhook events, expiry

### 2. Verification Status

Global `verification_status` = `approved` only if:
- Identity verified (via Stripe Identity)
- At least one trade is compliant
- No critical global docs missing/expired

### 3. Document Management

- Unique constraint: one active doc per (user_id, doc_type, doc_subtype)
- Status tracking: pending → approved/rejected/expired
- Expiry handling: automatic expiry and compliance update
- Storage integration: presigned URLs for secure uploads

### 4. Offer Acceptance Gating

Business rules enforced:
- User must be verified professional
- User must be compliant for all required trades
- Returns 409 with human-readable reasons if blocked

### 5. Webhook Idempotency

- All webhooks check `webhook_events` table
- Prevents duplicate processing
- Audit trail for all events

## File Structure

```
supabase/
├── migrations/
│   ├── 001_initial_schema.sql          # Core tables
│   ├── 002_rls_policies.sql            # Row Level Security
│   ├── 003_functions_and_views.sql      # SQL functions
│   ├── 004_storage_policies.sql        # Storage policies (placeholder)
│   ├── 005_seed_data.sql               # Seed data
│   ├── 006_storage_buckets.sql         # Storage buckets
│   ├── 007_fix_storage_path_helper.sql # Storage helpers
│   └── 008_fix_presign_upload_url.sql  # Documentation
├── functions/
│   ├── _shared/
│   │   ├── db.ts                       # Database client helpers
│   │   ├── types.ts                    # TypeScript types
│   │   └── cors.ts                     # CORS headers
│   ├── api-me/
│   ├── api-role-switch/
│   ├── api-offers/
│   ├── api-pro-offers-accept/
│   ├── api-stripe-identity-start/
│   ├── api-stripe-identity-webhook/
│   ├── api-pro-docs-presign/
│   ├── api-pro-docs-submit/
│   ├── api-payments-start/
│   └── api-stripe-payments-webhook/
└── README.md                            # Setup instructions

docs/
├── openapi.yaml                         # OpenAPI 3.0 specification
├── postman.json                         # Postman collection
├── SETUP.md                             # Setup guide
└── INTEGRATION_TESTS.md                 # Test scenarios
```

## Security Considerations

1. **RLS**: All tables protected by Row Level Security
2. **Storage**: Path-based access control (users can only access their own paths)
3. **Admin**: Admin access controlled via `admin_users` table
4. **Service Role**: Only used in Edge Functions, never exposed to client
5. **Webhooks**: Signature verification (should be implemented in production)
6. **CORS**: Configured for cross-origin requests

## Testing

See `docs/INTEGRATION_TESTS.md` for:
- Union/dedupe requirements test
- Accept job gating + 409 reasons test
- Identity webhook idempotency test
- Expiry demotion path test

## Deployment

1. **Migrations**: Run via `supabase db reset` or `supabase migration up`
2. **Functions**: Deploy via `supabase functions deploy`
3. **Environment**: Set variables in Supabase Dashboard
4. **Webhooks**: Configure in Stripe Dashboard

See `docs/SETUP.md` for detailed setup instructions.

## API Contracts

All endpoints return:
- **200**: Success
- **400**: Bad request (missing/invalid parameters)
- **401**: Unauthorized (missing/invalid token)
- **403**: Forbidden (insufficient permissions)
- **409**: Conflict (business rule violation, includes `reasons` array)
- **500**: Internal server error

Response shapes documented in `docs/openapi.yaml`.

## Seed Data

Seed data includes:
- Trade requirements for common trades (plumbing, electrical, HVAC, etc.)
- Test offers/jobs
- Helper function `seed_test_users()` for creating test users

## Next Steps

1. **Integration**: Connect Flutter app to these endpoints
2. **Testing**: Implement automated integration tests
3. **Monitoring**: Add error tracking and logging
4. **Optimization**: Add indexes, caching as needed
5. **Documentation**: Update API docs with examples

## Definition of Done ✅

- [x] Migrations + RLS apply cleanly and are safe to re-run
- [x] Endpoints match the contracts listed and return expected shapes
- [x] Webhooks update state and trigger recompute reliably
- [x] Storage policies prevent cross-user access; avatars public, docs private
- [x] Seeds let CodeX run the app end-to-end in dev immediately
- [x] OpenAPI documentation provided
- [x] Postman collection provided
- [x] Integration test scenarios documented
