# Complete Schema - README

## File Created

**`docs/COMPLETE_SCHEMA.sql`** - Complete database schema with all tables, functions, triggers, and seed data.

## What's Included

### ✅ Extensions
- `uuid-ossp` - UUID generation
- `pgcrypto` - Cryptographic functions
- `postgis` - Spatial/geographic data support

### ✅ Enum Types
- `account_type` - ('customer', 'professional')
- `role_type` - ('customer', 'professional')
- `verification_status` - ('pending', 'approved', 'rejected')
- `doc_status` - ('pending', 'approved', 'rejected', 'expired', 'manual_review')
- `job_status` - ('draft', 'requested', 'assigned', 'en_route', 'arrived', 'in_progress', 'completed', 'cancelled')
- `offer_status` - ('offered', 'accepted', 'declined', 'expired', 'withdrawn')
- `transaction_type` - ('hold', 'charge', 'payout', 'refund', 'adjustment')

### ✅ Tables
1. **users** - App-level user records (references auth.users(id) directly)
2. **customer_profiles** - Customer-specific data (addresses, preferences)
3. **professional_profiles** - Pro profiles with PostGIS location, service areas, availability
4. **services** - Master list of services (plumbing, electrical, etc.)
5. **trade_requirements** - Document requirements per service
6. **pro_documents** - Professional documents with status tracking
7. **pro_document_audits** - Audit trail for document changes
8. **pro_trade_compliance** - Cached compliance per user per service
9. **availability** - Pro availability calendar
10. **organizations** - Multi-tech company support
11. **org_members** - Organization membership
12. **jobs** - Job listings with full status flow
13. **job_events** - Status timeline and GPS breadcrumbs
14. **job_offers** - Fan-out of jobs to eligible pros
15. **transactions** - Payments/payouts ledger
16. **role_switches** - Audit of role toggles
17. **admin_users** - Admin allow-list
18. **webhook_events** - Webhook idempotency

### ✅ Indexes
- All necessary indexes for performance
- GIN indexes for arrays and JSONB
- GiST indexes for PostGIS geography types
- Partial unique indexes for active documents

### ✅ Views
- **v_user_active_docs** - Latest active documents per user, prioritizing approved > pending > manual_review

### ✅ Functions
- **recompute_pro_trade_compliance(user_id)** - Recomputes compliance for all services, updates verification_status

### ✅ Triggers
- **update_updated_at** - Automatically updates `updated_at` on all tables
- **trigger_recompute_compliance_on_doc_change** - Automatically recomputes compliance when documents change

### ✅ Seed Data
- Services: plumbing, electrical, hvac, locksmith, handyman, cleaning, landscaping, painting
- Trade requirements: Global (insurance_general, background_check) and service-specific requirements

### ✅ RLS Policies (Comments Only)
- All recommended RLS policies documented in comments
- Not enabled (to be applied later via separate migration)

## Features

### PostGIS Support
- `professional_profiles.base_location` - Geography(Point,4326) for pro location
- `job_events.location` - Geography(Point,4326) for GPS breadcrumbs
- Enables location-based queries (distance, proximity, service areas)

### Job Management System
- Full job lifecycle: draft → requested → assigned → en_route → arrived → in_progress → completed
- Event timeline with GPS tracking
- Job offers fan-out to eligible pros
- Distance-based matching

### Compliance System
- Automatic compliance recomputation
- Service-specific and global requirements
- Stripe Identity integration
- Automatic verification_status updates

### Multi-Tech Support
- Organizations and org_members tables
- Allows multiple pros to work under one company

## How to Use

1. **Copy the entire file**: `docs/COMPLETE_SCHEMA.sql`
2. **Open Supabase Dashboard** → SQL Editor
3. **Paste** the entire file
4. **Click Run** (or Cmd/Ctrl + Enter)
5. **Wait for "Success"** ✅

## Idempotency

✅ All statements are **idempotent** (safe to re-run):
- Uses `IF NOT EXISTS` for tables, indexes
- Uses `DO $$ BEGIN ... EXCEPTION` for types
- Uses `ON CONFLICT DO NOTHING` for seed data
- Uses `CREATE OR REPLACE` for functions, views, triggers

## Next Steps

1. **Apply RLS Policies**: Enable RLS and apply policies from comments
2. **Create Storage Buckets**: Create `pro-avatars` and `pro-docs` buckets
3. **Set up Edge Functions**: Deploy API endpoints
4. **Configure Webhooks**: Set up Stripe webhooks

## Important Notes

- ⚠️ **Users table**: Uses `auth.users(id)` directly as primary key (no separate `id` column)
- ⚠️ **Breaking change**: If you have existing data, this is a breaking change
- ✅ **PostGIS**: Required for location-based features
- ✅ **ENUMs**: Better type safety than TEXT with CHECK constraints
- ✅ **Full feature set**: Includes all tables for complete job management system

## File Location

**File**: `docs/COMPLETE_SCHEMA.sql`

**Size**: ~724 lines

**Status**: Ready to deploy ✅

