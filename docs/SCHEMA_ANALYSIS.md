# Schema Analysis: Current vs New Specification

## Key Differences to Discuss

### 1. **Extensions** ⚠️
**Current**: Only `uuid-ossp`
**New**: Also needs `pgcrypto` and `postgis`

**Impact**: PostGIS is significant - adds geography/geometry types for location data. Do you need spatial queries for location-based features?

### 2. **Users Table Structure** ⚠️
**Current**: 
- `id` (UUID) - separate app-level ID
- `auth_user_id` (UUID) - references `auth.users(id)`

**New**:
- `id` (UUID) - **directly references `auth.users(id)`** (no separate ID)
- Adds: `full_name`, `phone`, `email` columns

**Impact**: This is a **BREAKING CHANGE**. Current code uses `users.id` as the app-level ID. New schema uses `auth.users(id)` directly. This affects:
- All foreign key references
- All API endpoints
- All existing data

**Question**: Do you want to keep current structure (separate ID) or migrate to direct `auth.users(id)` reference?

### 3. **Enum Types** ⚠️
**Current**: Uses TEXT with CHECK constraints
**New**: Uses proper PostgreSQL ENUM types

**Impact**: Better type safety, but requires migration if you have existing data.

**Question**: Should we create ENUMs for better type safety, or keep TEXT with CHECK constraints?

### 4. **New Tables** ➕
**New tables needed**:
- `customer_profiles` - Customer-specific data (addresses, preferences)
- `services` - Master list of services (plumbing, electrical, etc.)
- `organizations` & `org_members` - Multi-tech company support
- `jobs` - Replaces `offers` table with more structure
- `job_events` - Status timeline and GPS breadcrumbs
- `job_offers` - Fan-out of jobs to eligible pros
- `transactions` - Payments/payouts ledger
- `role_switches` - Audit trail for role toggles
- `availability` - Pro availability calendar (replaces/extends current structure)

**Impact**: Significant schema expansion. This is a full feature set.

### 5. **Professional Profiles** ⚠️
**Current**: Simple structure
**New**: Adds:
- PostGIS `geography(Point,4326)` for `base_location`
- `service_area_km`, `available_days`, `working_hours` (JSONB)
- More structured identity/payouts fields

**Impact**: PostGIS required. Need to handle location data.

### 6. **Trade Requirements** ⚠️
**Current**: `trade` TEXT (NULL = global)
**New**: 
- References `services(code)` instead of TEXT
- Uses `service_code` instead of `trade`
- Adds `is_global` boolean flag
- Uses `kind` instead of `doc_type`

**Impact**: More structured, but requires `services` table first.

### 7. **Pro Documents** ⚠️
**Current**: Simple unique constraint
**New**: 
- Partial unique index (only for active docs)
- Adds `meta` JSONB field
- Uses `doc_status` enum instead of TEXT

**Impact**: Better indexing, but partial unique constraint is more complex.

### 8. **Jobs vs Offers** ⚠️
**Current**: `offers` table (simplified)
**New**: 
- `jobs` - Main job table with full status flow
- `job_events` - Timeline/audit trail
- `job_offers` - Fan-out to eligible pros

**Impact**: More complex job management system. Need to decide if you want this level of complexity.

### 9. **Compliance Function** ⚠️
**Current**: Uses `trade` TEXT, checks `v_user_active_docs` view
**New**: 
- Uses `services` table
- More sophisticated logic
- Updates `users.verification_status` automatically

**Impact**: More accurate compliance checking, but more complex.

### 10. **RLS Policies** ⚠️
**Current**: Applied in separate migration
**New**: Should be in comments only (not enabled)

**Impact**: Need to move RLS policies to comments section.

---

## Questions to Discuss

### 1. **Migration Strategy**
- Do you have existing data? If yes, we need a migration strategy.
- Should we keep current structure or migrate to new structure?

### 2. **PostGIS Dependency**
- Do you need spatial queries (distance, proximity, etc.)?
- PostGIS adds complexity but enables location-based features.

### 3. **Users Table**
- Keep current structure (separate `id` + `auth_user_id`) or migrate to direct `auth.users(id)` reference?
- This affects all foreign keys and code.

### 4. **Enum vs TEXT**
- Use PostgreSQL ENUMs (better type safety) or keep TEXT with CHECK constraints?
- ENUMs are better but harder to migrate.

### 5. **Feature Scope**
- Do you need all the new tables (organizations, job_events, transactions, etc.)?
- Or should we start with core tables and add others later?

### 6. **Job Management**
- Current: Simple `offers` table
- New: Full `jobs` + `job_events` + `job_offers` system
- Which level of complexity do you need?

---

## Recommended Approach

### Option A: Full New Schema (Recommended if starting fresh)
- Create all tables as specified
- Use ENUMs for type safety
- Use PostGIS for location features
- More comprehensive but requires migration

### Option B: Gradual Migration (Recommended if you have data)
- Keep current structure working
- Add new tables alongside existing ones
- Migrate gradually
- Less risky but more complex

### Option C: Hybrid Approach
- Keep current core tables (`users`, `professional_profiles`, `pro_documents`)
- Add new tables (`services`, `jobs`, etc.)
- Extend existing tables gradually
- Best of both worlds

---

## What Do You Want to Do?

1. **Keep current structure** and extend it?
2. **Migrate to new structure** completely?
3. **Hybrid approach** - keep what works, add what's new?

Let me know your preference and I'll create the SQL accordingly!

