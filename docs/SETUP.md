# Setup Guide for GetDone Backend

This guide walks you through setting up the GetDone backend using Supabase.

## Prerequisites

1. **Supabase Account**: Sign up at https://supabase.com
2. **Stripe Account**: Sign up at https://stripe.com (for payments and identity verification)
3. **Supabase CLI**: Install from https://supabase.com/docs/guides/cli
4. **Node.js 18+**: For running Supabase CLI

## Step 1: Initialize Supabase Project

```bash
# Login to Supabase
supabase login

# Initialize project (if starting fresh)
supabase init

# Link to your Supabase project
supabase link --project-ref your-project-ref
```

## Step 2: Apply Database Migrations

Run migrations in order:

```bash
# Apply all migrations
supabase db reset

# Or apply individually
supabase migration up
```

The migrations will:
1. Create all tables (users, professional_profiles, pro_documents, etc.)
2. Set up RLS policies
3. Create SQL functions and views
4. Create storage buckets
5. Insert seed data

## Step 3: Configure Storage Buckets

Storage buckets are created automatically by migration `006_storage_buckets.sql`. Verify in Supabase Dashboard:

1. Go to **Storage** → **Buckets**
2. Ensure `pro-avatars` (public) and `pro-docs` (private) exist
3. Verify policies are set correctly

## Step 4: Set Environment Variables

Set these in Supabase Dashboard → **Project Settings** → **Edge Functions**:

### Required Variables

- `SUPABASE_URL`: Auto-set (your project URL)
- `SUPABASE_ANON_KEY`: Auto-set (anon key)
- `SUPABASE_SERVICE_ROLE_KEY`: Your service role key (from Dashboard → Settings → API)

### Stripe Configuration

- `STRIPE_SECRET_KEY`: Your Stripe secret key (from Stripe Dashboard → Developers → API keys)
- `STRIPE_WEBHOOK_SECRET`: Webhook signing secret (from Stripe Dashboard → Developers → Webhooks)
- `STRIPE_IDENTITY_RETURN_URL`: URL to redirect after identity verification (e.g., `https://your-app.com/identity-return`)
- `STRIPE_CONNECT_RETURN_URL`: URL to redirect after Connect onboarding (e.g., `https://your-app.com/connect-return`)
- `STRIPE_CONNECT_REFRESH_URL`: URL to redirect for Connect account refresh (e.g., `https://your-app.com/connect-refresh`)

## Step 5: Deploy Edge Functions

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

## Step 6: Configure Stripe Webhooks

1. Go to **Stripe Dashboard** → **Developers** → **Webhooks**
2. Click **Add endpoint**
3. Set endpoint URL: `https://your-project-ref.supabase.co/functions/v1/api-stripe-identity-webhook`
4. Select events:
   - `identity.verification_session.verified`
   - `identity.verification_session.requires_input`
   - `identity.verification_session.processing`
   - `identity.verification_session.canceled`
5. Copy the **Signing secret** and add to environment variables as `STRIPE_WEBHOOK_SECRET`

Repeat for payments webhook:
- Endpoint: `https://your-project-ref.supabase.co/functions/v1/api-stripe-payments-webhook`
- Events:
  - `account.updated`
  - `account.application.deauthorized`

## Step 7: Set Up Cron Job (Optional)

For automatic document expiry, set up a cron job:

### Option 1: Using Supabase Dashboard
1. Go to **Database** → **Cron Jobs**
2. Create new job:
   - Schedule: `0 2 * * *` (2 AM daily)
   - SQL: `SELECT expire_pro_documents();`

### Option 2: Using pg_cron (if extension enabled)
```sql
SELECT cron.schedule(
  'expire-documents',
  '0 2 * * *',
  $$SELECT expire_pro_documents()$$
);
```

## Step 8: Create Test Users

To create test users, you need to:

1. **Create auth users** via Supabase Dashboard → **Authentication** → **Users**:
   - Email: `hvac_pro@example.com`
   - Email: `plumbing_pro@example.com`

2. **Run seed function**:
```sql
SELECT seed_test_users();
```

This will create app users and professional profiles with test data.

## Step 9: Test the API

### Using Postman

1. Import `docs/postman.json` into Postman
2. Set `base_url` variable: `https://your-project-ref.supabase.co/functions/v1`
3. Get a JWT token from Supabase:
   - Go to **Authentication** → **Users** → Select user → Copy token
   - Set `supabase_token` variable in Postman
4. Test endpoints starting with `GET /api/me`

### Using cURL

```bash
# Get current user
curl -X GET \
  'https://your-project-ref.supabase.co/functions/v1/api/me' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json'
```

## Step 10: Verify Setup

Run these checks:

1. **Database**: Verify tables exist and RLS is enabled
2. **Storage**: Verify buckets exist and policies are set
3. **Functions**: Test each endpoint with Postman
4. **Webhooks**: Send test webhook from Stripe Dashboard
5. **Compliance**: Create a professional user, upload documents, verify compliance calculation

## Troubleshooting

### Migration Errors

If migrations fail:
- Check Supabase logs in Dashboard
- Ensure extensions are enabled (`uuid-ossp`, `storage`)
- Verify RLS is enabled on all tables

### Edge Function Errors

- Check function logs: `supabase functions logs <function-name>`
- Verify environment variables are set
- Check CORS headers are correct

### Storage Upload Issues

- Verify bucket exists and policies are correct
- Check file path format matches expected structure
- Ensure user has proper permissions

### Webhook Issues

- Verify webhook secret matches
- Check webhook_events table for idempotency issues
- Ensure event types are subscribed in Stripe Dashboard

## Next Steps

1. **Integration**: Connect Flutter app to these endpoints
2. **Testing**: Run integration tests (see `docs/INTEGRATION_TESTS.md`)
3. **Monitoring**: Set up error tracking and logging
4. **Scaling**: Configure rate limiting and caching as needed

## Support

For issues or questions:
- Check Supabase documentation: https://supabase.com/docs
- Check Stripe documentation: https://stripe.com/docs
- Review API documentation: `docs/openapi.yaml`
