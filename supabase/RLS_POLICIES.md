# Row Level Security (RLS) Policies Documentation

This document provides a comprehensive overview of all Row Level Security (RLS) policies implemented in the GetDone Supabase database.

## Overview

All tables in the database have RLS enabled, ensuring that users can only access data they are authorized to view or modify. The security model follows these principles:

1. **User Isolation**: Users can only access their own data
2. **Admin Bypass**: Admins have elevated access to view and manage all data
3. **Path-Based Storage**: Storage access is controlled by path ownership (user_id in path)
4. **Audit Trail**: All document changes are automatically audited

## Helper Functions

### `is_admin(user_id UUID)`
- **Purpose**: Checks if a user is an admin
- **Returns**: `BOOLEAN`
- **Security**: `SECURITY DEFINER` (runs with elevated privileges)
- **Usage**: Used in policy conditions to grant admin access

### `auth_user_id()`
- **Purpose**: Gets the app-level `user_id` from the current authenticated `auth.uid()`
- **Returns**: `UUID` (app user.id, not auth.users.id)
- **Security**: `SECURITY DEFINER`
- **Usage**: Used in policy conditions to match user ownership

## Table Policies

### `users`

**Purpose**: App-level user records (not auth.users)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own record | SELECT | `auth_user_id = auth.uid()` |
| Users can update their own record | UPDATE | `auth_user_id = auth.uid()` |
| Admins can view all users | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Users cannot insert their own records (handled by application logic)
- Users cannot delete their own records (handled by application logic)
- Admins can view all users but cannot modify them directly

---

### `professional_profiles`

**Purpose**: Professional-specific data (services, Stripe Identity status, payouts)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own profile | SELECT | `user_id = auth_user_id()` |
| Users can update their own profile | UPDATE | `user_id = auth_user_id()` |
| Users can insert their own profile | INSERT | `user_id = auth_user_id()` |
| Admins can view all profiles | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Users can create and update their own professional profiles
- Profile creation requires matching `user_id` to authenticated user

---

### `pro_documents`

**Purpose**: Professional document uploads and verification status

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own documents | SELECT | `user_id = auth_user_id()` |
| Users can insert their own documents | INSERT | `user_id = auth_user_id()` |
| Users can update their own documents | UPDATE | `user_id = auth_user_id()` |
| Admins can view all documents | SELECT | `is_admin(auth_user_id())` |
| Admins can update all documents | UPDATE | `is_admin(auth_user_id())` |

**Notes**:
- Users can upload and update their own documents
- Admins can approve/reject documents (via UPDATE)
- Document deletion is handled by application logic (soft delete via status)

---

### `pro_documents_audits`

**Purpose**: Audit trail for all document changes

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own document audits | SELECT | `user_id = auth_user_id()` |
| Admins can view all document audits | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Audit records are created automatically by triggers (no manual INSERT)
- Users can view audit history for their own documents
- Admins can view all audit records for compliance

---

### `pro_trade_compliance`

**Purpose**: Trade compliance tracking (computed from documents and requirements)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own compliance | SELECT | `user_id = auth_user_id()` |
| Admins can view all compliance | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Compliance records are computed automatically (no manual INSERT/UPDATE)
- Users can view their own compliance status
- Admins can view all compliance records

---

### `trade_requirements`

**Purpose**: Global and trade-specific document requirements

| Policy | Operation | Condition |
|--------|-----------|-----------|
| (No RLS) | All | Public read (authenticated users) |

**Notes**:
- Trade requirements are read-only reference data
- No RLS policies (all authenticated users can read)
- Updates require admin privileges via service role

---

### `admin_users`

**Purpose**: Admin access control

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Admins can view admin list | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Only admins can view the admin list
- Admin assignment requires service role access

---

### `webhook_events`

**Purpose**: Webhook event idempotency and audit

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Admins can view webhook events | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Webhook events are created by Edge Functions (service role)
- Only admins can view webhook event history

---

### `offers`

**Purpose**: Job listings/offers

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Authenticated users can view offers | SELECT | `auth.uid() IS NOT NULL` |
| Customers can create offers | INSERT | `auth.uid() IS NOT NULL AND (customer_user_id = auth_user_id() OR customer_user_id IS NULL)` |
| Offer owners can update their offers | UPDATE | `customer_user_id = auth_user_id()` |
| Admins can manage all offers | ALL | `is_admin(auth_user_id())` |

**Notes**:
- All authenticated users can view offers (public listing)
- Users can create offers (becomes the owner)
- Only offer owners can update their offers
- Admins have full access (SELECT, INSERT, UPDATE, DELETE)

---

### `offer_assignments`

**Purpose**: Job assignments (pros assigned to offers)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view assignments for their offers | SELECT | `EXISTS (SELECT 1 FROM offers WHERE offers.id = offer_assignments.offer_id AND offers.customer_user_id = auth_user_id())` |
| Professionals can view their own assignments | SELECT | `professional_user_id = auth_user_id()` |
| Admins can view all assignments | SELECT | `is_admin(auth_user_id())` |

**Notes**:
- Offer owners can see who is assigned to their offers
- Professionals can see offers they're assigned to
- Assignment creation/deletion handled by application logic (service role)

---

## Storage Policies

### `pro-avatars` Bucket (Public Read)

**Purpose**: User avatars (publicly viewable)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Public avatars are viewable by everyone | SELECT | `bucket_id = 'pro-avatars'` |
| Users can upload their own avatar | INSERT | `bucket_id = 'pro-avatars' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |
| Users can update their own avatar | UPDATE | `bucket_id = 'pro-avatars' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |
| Users can delete their own avatar | DELETE | `bucket_id = 'pro-avatars' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |

**Path Structure**: `pro-avatars/{auth.uid()}/{filename}`

**Notes**:
- Anyone can view avatars (public read)
- Users can only upload/update/delete to their own path
- Path must start with `{auth.uid()}`

---

### `pro-docs` Bucket (Private)

**Purpose**: Professional documents (private, user-only access)

| Policy | Operation | Condition |
|--------|-----------|-----------|
| Users can view their own documents | SELECT | `bucket_id = 'pro-docs' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |
| Users can upload their own documents | INSERT | `bucket_id = 'pro-docs' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |
| Users can update their own documents | UPDATE | `bucket_id = 'pro-docs' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text` |
| Admins can view all documents | SELECT | `bucket_id = 'pro-docs' AND EXISTS (SELECT 1 FROM users u JOIN admin_users au ON au.user_id = u.id WHERE u.auth_user_id = auth.uid())` |

**Path Structure**: `pro-docs/{auth.uid()}/{doc_type}/{doc_subtype|default}/{uuid}.{extension}`

**Notes**:
- Documents are private (only owner can access)
- Users can only upload/update to their own path
- Admins can view all documents (for verification)
- Path must start with `{auth.uid()}`

---

## Security Considerations

### 1. Cross-User Data Access Prevention

**Enforcement**:
- All policies use `auth_user_id()` to match user ownership
- Policies explicitly check `user_id = auth_user_id()` for user-specific tables
- Storage policies enforce path-based ownership via `auth.uid()` in path

**Testing**:
- Users cannot query other users' data
- Users cannot update other users' records
- Users cannot access other users' storage paths

### 2. Admin Bypass

**Enforcement**:
- Admin check via `is_admin(auth_user_id())` function
- Admin status stored in `admin_users` table
- Admins can view all data but cannot modify via policies (handled by application logic)

**Testing**:
- Admins can view all users, profiles, documents
- Admins can update documents (for approval/rejection)
- Admins cannot directly modify user records (via service role only)

### 3. Audit Trail

**Enforcement**:
- `pro_documents_audits` table tracks all document changes
- Triggers automatically create audit records
- Audit records follow same RLS policies as documents

**Testing**:
- Users can view audit history for their own documents
- Admins can view all audit records
- Audit records cannot be manually inserted (trigger-only)

### 4. Storage Path Validation

**Enforcement**:
- Storage policies validate path structure: `{auth.uid()}/...`
- Path ownership enforced via `storage.foldername(name)[1] = auth.uid()::text`
- Admin bypass for `pro-docs` bucket (read-only)

**Testing**:
- Users cannot access other users' storage paths
- Users cannot upload to other users' paths
- Path structure must match expected format

## Migration Safety

All RLS policies are **idempotent**:
- Policies use `DROP POLICY IF EXISTS` before `CREATE POLICY`
- Multiple runs of migration files are safe
- Policies can be updated without breaking existing data

## Testing RLS Policies

### Manual Testing

```sql
-- Test user isolation (should only see own data)
SELECT * FROM users; -- Should return only current user
SELECT * FROM pro_documents; -- Should return only own documents

-- Test admin access (should see all data)
-- (When logged in as admin)
SELECT * FROM users; -- Should return all users
SELECT * FROM pro_documents; -- Should return all documents

-- Test storage access
-- (Via Supabase Storage API)
-- Should only be able to access own paths
```

### Automated Testing

- Use Supabase test client with different user credentials
- Verify policy conditions with `EXPLAIN` queries
- Test edge cases (null values, missing records, etc.)

## Common Issues

### Issue: User cannot see their own data
**Solution**: Verify `auth_user_id()` function returns correct user_id

### Issue: Admin cannot see all data
**Solution**: Verify `is_admin()` function and admin_users table

### Issue: Storage upload fails
**Solution**: Verify path structure matches `{auth.uid()}/...` pattern

### Issue: Policies not applying
**Solution**: Verify RLS is enabled: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`

