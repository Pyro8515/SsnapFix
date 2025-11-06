# Quick Start - Copy & Paste SQL into Supabase

## ✅ Option 1: Combined File (EASIEST!)

**File**: `docs/ALL_MIGRATIONS_COMBINED.sql`

1. Open Supabase Dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Open `docs/ALL_MIGRATIONS_COMBINED.sql` in your editor
5. Copy the **entire file** (Cmd/Ctrl + A, then Cmd/Ctrl + C)
6. Paste into Supabase SQL Editor
7. Click **Run** (or press Cmd/Ctrl + Enter)
8. Wait for "Success" ✅

**Done!** All migrations applied in one go.

---

## ✅ Option 2: Run Files One by One

Copy and paste these files **in this exact order**:

1. `supabase/migrations/001_initial_schema.sql` ⭐
2. `supabase/migrations/002_rls_policies.sql` ⭐
3. `supabase/migrations/003_functions_and_views.sql` ⭐
4. `supabase/migrations/006_storage_buckets.sql` ⭐
5. `supabase/migrations/007_fix_storage_path_helper.sql` ⭐
6. `supabase/migrations/009_pro_documents_audits.sql` ⭐
7. `supabase/migrations/010_rls_audit_table.sql` ⭐

**Optional** (run if they exist):
- `supabase/migrations/004_storage_policies.sql`
- `supabase/migrations/005_seed_data.sql` (Dev only - SKIP for production!)
- `supabase/migrations/008_fix_presign_upload_url.sql` (SKIP - docs only)
- `supabase/migrations/011_notifications_table.sql`
- `supabase/migrations/011_recompute_triggers.sql`
- `supabase/migrations/012_improve_requirements_union.sql`
- `supabase/migrations/012_realtime_setup.sql`
- `supabase/migrations/013_document_expiry_reminders.sql`
- `supabase/migrations/014_notifications_rls.sql`

---

## 📁 File Locations

All SQL files are in: `supabase/migrations/`

Combined file is in: `docs/ALL_MIGRATIONS_COMBINED.sql`

---

## ⚠️ Important Notes

- ✅ All migrations are **idempotent** (safe to run multiple times)
- ✅ Run them **in order** (001, 002, 003, etc.)
- ⚠️ Skip `005_seed_data.sql` for production
- ⚠️ Skip `008_fix_presign_upload_url.sql` (docs only, no SQL)

---

## ✅ After Running

1. **Verify Storage Buckets**:
   - Go to **Storage** → **Buckets**
   - Should see: `pro-avatars` (public) and `pro-docs` (private)

2. **Verify Tables**:
   - Go to **Table Editor**
   - Should see: users, professional_profiles, pro_documents, etc.

3. **Verify Functions**:
   - Go to **Database** → **Functions**
   - Should see: recompute_pro_trade_compliance, etc.

---

## 🎯 Recommended: Use Combined File!

**Just copy `docs/ALL_MIGRATIONS_COMBINED.sql` and paste it into Supabase SQL Editor - done!**

