# SQL Migration Guide - Copy & Paste into Supabase SQL Editor

## Simple Instructions

1. Go to your Supabase Dashboard → SQL Editor
2. Copy each SQL file below **in order** (one at a time)
3. Paste into SQL Editor and click "Run"
4. Repeat for each file

---

## Migration Files (Run in Order)

### ✅ Step 1: Initial Schema
**File**: `supabase/migrations/001_initial_schema.sql`
- Creates all tables (users, professional_profiles, pro_documents, etc.)
- Sets up indexes and triggers

### ✅ Step 2: Row Level Security (RLS)
**File**: `supabase/migrations/002_rls_policies.sql`
- Sets up RLS policies for all tables
- Ensures users can only access their own data

### ✅ Step 3: Functions and Views
**File**: `supabase/migrations/003_functions_and_views.sql`
- Creates SQL functions (recompute_pro_trade_compliance, etc.)
- Creates views (v_user_active_docs)

### ✅ Step 4: Storage Policies (Optional - Placeholder)
**File**: `supabase/migrations/004_storage_policies.sql`
- Helper function for storage (can skip if using Step 6)

### ✅ Step 5: Seed Data (Optional - Development Only)
**File**: `supabase/migrations/005_seed_data.sql`
- Adds test data for development
- **Skip this for production!**

### ✅ Step 6: Storage Buckets (IMPORTANT)
**File**: `supabase/migrations/006_storage_buckets.sql`
- Creates `pro-avatars` bucket (public)
- Creates `pro-docs` bucket (private)
- Sets up storage policies

### ✅ Step 7: Storage Path Helper
**File**: `supabase/migrations/007_fix_storage_path_helper.sql`
- Storage path helper function

### ✅ Step 8: Presign URL Documentation
**File**: `supabase/migrations/008_fix_presign_upload_url.sql`
- Documentation only (no SQL to run)
- **You can skip this one**

### ✅ Step 9: Document Audits
**File**: `supabase/migrations/009_pro_documents_audits.sql`
- Creates audit table and triggers
- Automatically tracks all document changes

### ✅ Step 10: Audit RLS
**File**: `supabase/migrations/010_rls_audit_table.sql`
- Sets up RLS policies for audit table

### ✅ Step 11: Notifications (If exists)
**File**: `supabase/migrations/011_notifications_table.sql`
- Creates notifications table (if file exists)

### ✅ Step 12: Recompute Triggers (If exists)
**File**: `supabase/migrations/011_recompute_triggers.sql`
- Triggers for compliance recomputation (if file exists)

### ✅ Step 13: Requirements Union (If exists)
**File**: `supabase/migrations/012_improve_requirements_union.sql`
- Improvements to requirements (if file exists)

### ✅ Step 14: Realtime Setup (If exists)
**File**: `supabase/migrations/012_realtime_setup.sql`
- Sets up Realtime subscriptions (if file exists)

### ✅ Step 15: Document Expiry Reminders (If exists)
**File**: `supabase/migrations/013_document_expiry_reminders.sql`
- Expiry reminder triggers (if file exists)

### ✅ Step 16: Notifications RLS (If exists)
**File**: `supabase/migrations/014_notifications_rls.sql`
- RLS policies for notifications (if file exists)

---

## Quick Checklist

Copy and paste these files **in this exact order**:

- [ ] `001_initial_schema.sql` ⭐ **REQUIRED**
- [ ] `002_rls_policies.sql` ⭐ **REQUIRED**
- [ ] `003_functions_and_views.sql` ⭐ **REQUIRED**
- [ ] `004_storage_policies.sql` (Optional)
- [ ] `005_seed_data.sql` (Optional - Dev only)
- [ ] `006_storage_buckets.sql` ⭐ **REQUIRED**
- [ ] `007_fix_storage_path_helper.sql` ⭐ **REQUIRED**
- [ ] `008_fix_presign_upload_url.sql` (Skip - docs only)
- [ ] `009_pro_documents_audits.sql` ⭐ **REQUIRED**
- [ ] `010_rls_audit_table.sql` ⭐ **REQUIRED**
- [ ] `011_notifications_table.sql` (If exists)
- [ ] `011_recompute_triggers.sql` (If exists)
- [ ] `012_improve_requirements_union.sql` (If exists)
- [ ] `012_realtime_setup.sql` (If exists)
- [ ] `013_document_expiry_reminders.sql` (If exists)
- [ ] `014_notifications_rls.sql` (If exists)

---

## Or: Use Combined File (Easier!)

I've also created a combined SQL file with all migrations in order:
- **File**: `docs/ALL_MIGRATIONS_COMBINED.sql`

You can copy this **entire file** and paste it into Supabase SQL Editor all at once!

---

## How to Use

1. Open Supabase Dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the SQL file content
5. Paste into the editor
6. Click **Run** (or press Cmd/Ctrl + Enter)
7. Wait for "Success" message
8. Repeat for next file

---

## Important Notes

- ✅ All migrations are **idempotent** (safe to run multiple times)
- ✅ Run them **in order** (001, 002, 003, etc.)
- ✅ Skip `005_seed_data.sql` for production
- ✅ Skip `008_fix_presign_upload_url.sql` (docs only)
- ✅ Files marked with "If exists" are optional

---

## After Running Migrations

1. **Verify Storage Buckets**:
   - Go to **Storage** → **Buckets**
   - Should see `pro-avatars` (public) and `pro-docs` (private)

2. **Verify Tables**:
   - Go to **Table Editor**
   - Should see: users, professional_profiles, pro_documents, etc.

3. **Verify Functions**:
   - Go to **Database** → **Functions**
   - Should see: recompute_pro_trade_compliance, etc.

---

## Need Help?

If you get any errors:
1. Check the error message
2. Make sure you ran files in order
3. Try running the file again (migrations are idempotent)

