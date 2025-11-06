# SQL Files to Run - In Order

## Quick Reference

Copy and paste these files **in this exact order** into Supabase SQL Editor:

### Required Files (Run These First)

1. ✅ `supabase/migrations/001_initial_schema.sql`
2. ✅ `supabase/migrations/002_rls_policies.sql`
3. ✅ `supabase/migrations/003_functions_and_views.sql`
4. ✅ `supabase/migrations/006_storage_buckets.sql`
5. ✅ `supabase/migrations/007_fix_storage_path_helper.sql`
6. ✅ `supabase/migrations/009_pro_documents_audits.sql`
7. ✅ `supabase/migrations/010_rls_audit_table.sql`

### Optional Files (Run If They Exist)

8. ⚠️ `supabase/migrations/004_storage_policies.sql` (Optional)
9. ⚠️ `supabase/migrations/005_seed_data.sql` (Dev only - SKIP for production!)
10. ⚠️ `supabase/migrations/008_fix_presign_upload_url.sql` (SKIP - docs only, no SQL)
11. ⚠️ `supabase/migrations/011_notifications_table.sql` (If exists)
12. ⚠️ `supabase/migrations/011_recompute_triggers.sql` (If exists)
13. ⚠️ `supabase/migrations/012_improve_requirements_union.sql` (If exists)
14. ⚠️ `supabase/migrations/012_realtime_setup.sql` (If exists)
15. ⚠️ `supabase/migrations/013_document_expiry_reminders.sql` (If exists)
16. ⚠️ `supabase/migrations/014_notifications_rls.sql` (If exists)

---

## Or: Use Combined File (EASIEST!)

**File**: `docs/ALL_MIGRATIONS_COMBINED.sql`

This file contains **ALL migrations in order**. Just copy the entire file and paste it into Supabase SQL Editor!

---

## How to Run

1. Open Supabase Dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the SQL file content
5. Paste into editor
6. Click **Run** (or Cmd/Ctrl + Enter)
7. Wait for "Success" ✅
8. Repeat for next file

---

## File Locations

All SQL files are in: `supabase/migrations/`

The combined file is in: `docs/ALL_MIGRATIONS_COMBINED.sql`

