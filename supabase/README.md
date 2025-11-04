# Supabase Backend for GetDone

This directory contains the backend implementation for the GetDone platform using Supabase.

## Structure

- `migrations/` - Database migrations (run in order)
- `functions/` - Supabase Edge Functions (API endpoints)

## Setup

### 1. Database Migrations

Run migrations in order:

```bash
# Using Supabase CLI
supabase db reset  # Resets and applies all migrations

# Or apply individually
supabase migration up
```

Migrations (run in order):
1. `001_initial_schema.sql` - Core tables and schema (idempotent)
2. `002_rls_policies.sql` - Row Level Security policies (idempotent)
3. `003_functions_and_views.sql` - SQL functions and views (idempotent)
4. `004_storage_policies.sql` - Storage bucket policies (placeholder)
5. `005_seed_data.sql` - Seed data for development
6. `006_storage_buckets.sql` - Storage buckets and policies (idempotent)
7. `007_fix_storage_path_helper.sql` - Storage path helper function
8. `008_fix_presign_upload_url.sql` - Storage path documentation
9. `009_pro_documents_audits.sql` - Document audit table and triggers (idempotent)
10. `010_rls_audit_table.sql` - RLS policies for audit table (idempotent)

**All migrations are idempotent** - safe to run multiple times.

### 2. Storage Buckets

Storage buckets and policies are created automatically by migration `006_storage_buckets.sql`:

- **pro-avatars** (public): Public read, authenticated users can upload to their own path
  - Path structure: `pro-avatars/{auth.uid()}/{filename}`
  - Policies: Public read, authenticated write to own path
  
- **pro-docs** (private): Private, only users can access their own documents, admins can view all
  - Path structure: `pro-docs/{auth.uid()}/{doc_type}/{doc_subtype|default}/{uuid}.{extension}`
  - Policies: User-only access, admin read-all

### 3. Environment Variables

Set these in Supabase Dashboard → Project Settings → Edge Functions:

- `SUPABASE_URL` - Your Supabase project URL (auto-set)
- `SUPABASE_ANON_KEY` - Your Supabase anon key (auto-set)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (for admin operations)
- `STRIPE_SECRET_KEY` - Stripe secret key
- `STRIPE_WEBHOOK_SECRET` - Stripe webhook signing secret
- `STRIPE_IDENTITY_RETURN_URL` - Return URL after identity verification
- `STRIPE_CONNECT_RETURN_URL` - Return URL after Connect onboarding
- `STRIPE_CONNECT_REFRESH_URL` - Refresh URL for Connect account links

### 4. Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy

# Or deploy individually
supabase functions deploy api-me
supabase functions deploy api-role-switch
supabase functions deploy api-offers
supabase functions deploy api-pro-offers-accept
supabase functions deploy api-stripe-identity-start
supabase functions deploy api-stripe-identity-webhook
supabase functions deploy api-pro-docs-presign
supabase functions deploy api-pro-docs-submit
supabase functions deploy api-payments-start
supabase functions deploy api-stripe-payments-webhook
```

### 5. Webhook Configuration

Configure Stripe webhooks to point to your Edge Functions:

- **Identity webhook**: `https://<project-ref>.supabase.co/functions/v1/api-stripe-identity-webhook`
- **Payments webhook**: `https://<project-ref>.supabase.co/functions/v1/api-stripe-payments-webhook`

Listen for events:
- `identity.verification_session.verified`
- `identity.verification_session.requires_input`
- `identity.verification_session.processing`
- `identity.verification_session.canceled`
- `account.updated`
- `account.application.deauthorized`

### 6. Cron Jobs (Optional)

Set up a cron job to expire documents nightly:

```sql
-- Create a pg_cron job (if extension enabled)
SELECT cron.schedule(
  'expire-documents',
  '0 2 * * *', -- 2 AM daily
  $$SELECT expire_pro_documents()$$
);
```

Or use Supabase's cron functionality or external scheduler.

## API Endpoints

All endpoints require authentication via `Authorization: Bearer <token>` header unless noted.

See `docs/openapi.yaml` for complete API documentation.

## Testing

See `docs/postman.json` for Postman collection with example requests.

## Seed Data

Run `supabase/seed.sql` to create:
- Trade requirements for common trades (plumbing, HVAC, electrical, painting, locksmith)
- Sample offers (7 sample jobs)
- Helper function `seed_test_users()` for creating test users

**Usage:**
```sql
-- Run seed file
\i supabase/seed.sql

-- Or create test users manually:
-- 1. Create auth.users entries first (via Supabase Auth API or Dashboard):
--    - hvac_pro@example.com
--    - plumbing_pro@example.com
-- 2. Run: SELECT * FROM seed_test_users();
```

**Seed Data Includes:**
- One **approved professional** (HVAC + Painting) with complete documents
- One **pending professional** (Plumbing) with missing required documents
- Trade requirements for all supported trades
- Sample offers for testing

Note: The `seed_test_users()` function requires corresponding `auth.users` entries first.

## Row Level Security (RLS)

All tables have RLS enabled with comprehensive policies:

- **User Isolation**: Users can only access their own data
- **Admin Bypass**: Admins have elevated access to view and manage all data
- **Path-Based Storage**: Storage access is controlled by path ownership (`auth.uid()` in path)
- **Audit Trail**: All document changes are automatically audited

See `RLS_POLICIES.md` for comprehensive RLS documentation including:
- All table policies
- Storage bucket policies
- Security considerations
- Testing guidelines

## Database Schema

### Core Tables

- **users**: App-level user records (account_type, active_role, can_switch_roles, verification_status, avatar_url)
- **professional_profiles**: Professional-specific data (identity_ref_id, services[], payouts_status)
- **pro_documents**: Document uploads and verification status
- **pro_documents_audits**: Audit trail for all document changes (automatic)
- **pro_trade_compliance**: Trade compliance tracking (computed)
- **trade_requirements**: Global and trade-specific document requirements
- **admin_users**: Admin access control
- **webhook_events**: Webhook idempotency and audit
- **offers**: Job listings/offers
- **offer_assignments**: Job assignments (pros assigned to offers)

### Functions

- `recompute_pro_trade_compliance(user_id)`: Recomputes trade compliance for a user
- `expire_pro_documents()`: Marks expired documents and triggers compliance recomputation
- `seed_test_users()`: Creates test users (requires auth.users entries)

### Views

- `v_user_active_docs`: Latest active/approved documents per user

## Idempotency

**All migrations are idempotent** - safe to run multiple times:
- Tables use `CREATE TABLE IF NOT EXISTS`
- Policies use `DROP POLICY IF EXISTS` before `CREATE POLICY`
- Functions use `CREATE OR REPLACE FUNCTION`
- Triggers use `DROP TRIGGER IF EXISTS` before `CREATE TRIGGER`
- Indexes use `CREATE INDEX IF NOT EXISTS`
- Views use `CREATE OR REPLACE VIEW`
