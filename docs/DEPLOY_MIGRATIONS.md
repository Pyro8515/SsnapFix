# How to Apply Migrations to Supabase

## Option 1: Supabase CLI (Recommended) ✅

This is the easiest and recommended way to apply migrations.

### Prerequisites
- Supabase CLI installed
- Your Supabase project linked

### Steps

1. **Install Supabase CLI** (if not already installed):
```bash
npm install -g supabase
# or
brew install supabase/tap/supabase
```

2. **Login to Supabase**:
```bash
supabase login
```

3. **Link to your project**:
```bash
supabase link --project-ref your-project-ref
```
You can find your project ref in Supabase Dashboard → Settings → General

4. **Apply all migrations**:
```bash
cd supabase
supabase db push
```

This will apply all migrations in order.

### What I Need From You:
- ✅ Your Supabase project reference ID (found in Dashboard → Settings → General)
- ✅ Access to run Supabase CLI commands (or I can provide you with the commands)

---

## Option 2: Supabase Dashboard SQL Editor

If you prefer using the web interface, you can copy-paste migrations into the SQL Editor.

### Steps

1. Go to Supabase Dashboard → SQL Editor
2. Copy each migration file content
3. Paste and run in order

### What I Need From You:
- ✅ Access to your Supabase Dashboard
- ✅ I can provide you with a combined SQL file that runs all migrations in order

---

## Option 3: Direct Database Connection Script

I can create a Node.js script that connects directly to your database and runs all migrations.

### What I Need From You:
- ✅ Database connection string (found in Dashboard → Settings → Database → Connection string)
- ✅ Or: Database URL, password, and database name

---

## Option 4: Prisma (Not Recommended for Supabase)

While Prisma can work with PostgreSQL (which Supabase uses), it's not the standard approach for Supabase. However, if you really want to use Prisma:

### What I Need From You:
- ✅ Database connection string
- ✅ Permission to set up Prisma schema

**Note**: This would require converting SQL migrations to Prisma migrations, which is more complex.

---

## Recommended Approach

**I recommend Option 1 (Supabase CLI)** because:
- ✅ It's the official Supabase way
- ✅ Handles migration ordering automatically
- ✅ Tracks which migrations have been applied
- ✅ Safe to run multiple times (migrations are idempotent)
- ✅ Can be automated in CI/CD

---

## What I Need From You

To help you apply the migrations, please provide:

1. **Your Supabase Project Reference** (e.g., `abcdefghijklmnop`)
   - Found in: Dashboard → Settings → General → Reference ID

2. **Access Method Preference**:
   - [ ] Option 1: Supabase CLI (I'll provide commands)
   - [ ] Option 2: Combined SQL file (I'll create it)
   - [ ] Option 3: Node.js script (I'll create it)
   - [ ] Option 4: Prisma setup (I'll set it up)

3. **Environment**:
   - [ ] Local development
   - [ ] Staging
   - [ ] Production

4. **Existing Data**:
   - [ ] Fresh database (safe to reset)
   - [ ] Existing data (need to preserve)

---

## Migration Files to Apply (in order)

All migrations are **idempotent** (safe to run multiple times):

1. `001_initial_schema.sql` - Core tables
2. `002_rls_policies.sql` - Row Level Security
3. `003_functions_and_views.sql` - SQL functions
4. `004_storage_policies.sql` - Storage policies (placeholder)
5. `005_seed_data.sql` - Seed data (optional)
6. `006_storage_buckets.sql` - Storage buckets
7. `007_fix_storage_path_helper.sql` - Storage helper
8. `008_fix_presign_upload_url.sql` - Storage docs
9. `009_pro_documents_audits.sql` - Audit table
10. `010_rls_audit_table.sql` - Audit RLS
11. `011_notifications_table.sql` - Notifications (if exists)
12. `011_recompute_triggers.sql` - Triggers (if exists)
13. `012_improve_requirements_union.sql` - Requirements (if exists)
14. `012_realtime_setup.sql` - Realtime (if exists)
15. `013_document_expiry_reminders.sql` - Expiry reminders (if exists)
16. `014_notifications_rls.sql` - Notifications RLS (if exists)

---

## Quick Start (If You Have Supabase CLI)

```bash
# Navigate to project
cd /Users/pyrocrixis/StudioProjects/getdone

# Link to your project (replace with your project ref)
supabase link --project-ref YOUR_PROJECT_REF

# Apply all migrations
supabase db push

# Verify
supabase db diff
```

---

## Next Steps

Once you provide the information above, I can:
1. Create a combined SQL file (all migrations in one)
2. Create a Node.js script to apply migrations
3. Provide exact Supabase CLI commands
4. Set up Prisma (if you prefer)

**Just let me know which option you prefer and provide the required information!**

