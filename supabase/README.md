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

Migrations:
1. `001_initial_schema.sql` - Core tables and schema
2. `002_rls_policies.sql` - Row Level Security policies
3. `003_functions_and_views.sql` - SQL functions and views
4. `004_storage_policies.sql` - Storage bucket policies (placeholder)
5. `005_seed_data.sql` - Seed data for development

### 2. Storage Buckets

Create storage buckets via Supabase Dashboard or CLI:

```sql
-- Create buckets (run in Supabase SQL editor)
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('pro-avatars', 'pro-avatars', true),
  ('pro-docs', 'pro-docs', false);
```

Storage policies should be set via Supabase Dashboard:
- **pro-avatars**: Public read, authenticated users can upload to their own path
- **pro-docs**: Private, only users can access their own documents, admins can view all

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

Run `005_seed_data.sql` to create:
- Trade requirements for common trades
- Helper function `seed_test_users()` for creating test users

Note: Test users require corresponding `auth.users` entries first.
