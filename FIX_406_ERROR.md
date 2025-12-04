# 🔧 Fix: 406 Not Acceptable Error

## Problem

You're getting this error:
```
GET https://hxqyzopmpvkjjkdpttlu.supabase.co/rest/v1/auth_users?... 406 (Not Acceptable)
❌ Federated identity login failed: user_not_provisioned
```

This means the `auth_users` table either:
1. **Doesn't exist** in your new Supabase project, OR
2. **Exists but isn't accessible** via the REST API

## Quick Fix (5 minutes)

### Step 1: Check if Tables Exist

Go to **Supabase Dashboard → SQL Editor** and run:

```sql
-- Check if auth tables exist
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE 'auth_%';
```

**Expected Result:**
```
auth_organizations
auth_users
auth_user_profiles
```

### Step 2A: If Tables DON'T Exist

Run the complete setup script:

1. Open `database/migrations/01_complete_auth_setup.sql`
2. Copy ALL contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. Wait for "✅ Authentication setup complete!"

Then proceed to Step 3.

### Step 2B: If Tables DO Exist

The tables exist but the user isn't provisioned. Skip to Step 3.

### Step 3: Provision Your User

Run the quick provision script:

1. Open `database/migrations/05_quick_provision_user.sql`
2. Copy ALL contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. You should see: "✅ User provisioned successfully!"

### Step 4: Test Login

1. Refresh your browser (F5)
2. Try logging in again
3. You should now be authenticated! 🎉

## Detailed Diagnosis

### Check 1: Verify Supabase Connection

Make sure your `.env` has the correct values:

```bash
# Should point to NEW project
VITE_SUPABASE_URL=https://hxqyzopmpvkjjkdpttlu.supabase.co
VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Backend should match
SUPABASE_URL=https://hxqyzopmpvkjjkdpttlu.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Verify:**
- URLs match your new project
- Service role key is from the NEW project (not old one)
- No extra spaces or line breaks

### Check 2: Verify Service Role Key

1. Go to Supabase Dashboard → **Settings → API**
2. Find **service_role** key (NOT anon key)
3. Copy it
4. Compare with `VITE_SUPABASE_SERVICE_ROLE_KEY` in `.env`
5. They should match EXACTLY

### Check 3: Restart Dev Server

After changing `.env`:

```bash
# Stop the dev server (Ctrl+C)
# Start it again
npm run dev
```

Environment variables are only loaded on startup.

### Check 4: Verify Table Structure

Run in Supabase SQL Editor:

```sql
-- Check auth_users structure
\d auth_users

-- Or use this:
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'auth_users';
```

**Expected columns:**
- id (uuid)
- email (text)
- name (text)
- azure_oid (text) ← **IMPORTANT**
- azure_sub (text)
- is_active (boolean)
- created_at (timestamptz)
- updated_at (timestamptz)

### Check 5: Verify RLS Policies

```sql
-- Check if service_role can access auth_users
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'auth_users'
  AND grantee = 'service_role';
```

**Expected:** Should show SELECT, INSERT, UPDATE, DELETE privileges

## Common Issues

### Issue 1: "Table doesn't exist"

**Solution:** Run `01_complete_auth_setup.sql`

### Issue 2: "Invalid API key"

**Solution:** 
- Check `VITE_SUPABASE_SERVICE_ROLE_KEY` in `.env`
- Get correct key from Supabase Dashboard → Settings → API
- Restart dev server

### Issue 3: "User not provisioned"

**Solution:** Run `05_quick_provision_user.sql`

### Issue 4: "406 Not Acceptable"

**Causes:**
1. Table doesn't exist → Run setup script
2. Wrong API key → Update `.env`
3. RLS blocking access → Check grants
4. Wrong Supabase URL → Verify `.env`

**Solution:** Follow steps above in order

## Manual User Provisioning

If you want to provision a different user, use this template:

```sql
-- 1. Create organization (if needed)
INSERT INTO auth_organizations (name, display_name, type, status)
VALUES ('your-org', 'Your Organization', 'staff', 'Active')
ON CONFLICT (name) DO NOTHING;

-- 2. Create user with Azure OID
INSERT INTO auth_users (email, name, azure_oid, is_active)
VALUES (
  'user@example.com',
  'User Name',
  'azure-oid-from-console',  -- Get from browser console
  true
)
ON CONFLICT (email) DO UPDATE 
SET azure_oid = EXCLUDED.azure_oid;

-- 3. Create profile
INSERT INTO auth_user_profiles (user_id, organization_id, role, user_segment)
SELECT 
  u.id,
  o.id,
  'admin',     -- or 'viewer', 'approver', etc.
  'internal'   -- or 'partner', 'customer', 'advisor'
FROM auth_users u
CROSS JOIN auth_organizations o
WHERE u.email = 'user@example.com'
  AND o.name = 'your-org'
ON CONFLICT (user_id, organization_id) DO NOTHING;
```

## Verify Everything Works

After fixing, run this check:

```sql
-- Should return your user
SELECT 
  u.email,
  u.azure_oid,
  o.display_name as org,
  p.role,
  p.user_segment
FROM auth_users u
JOIN auth_user_profiles p ON u.id = p.user_id
JOIN auth_organizations o ON p.organization_id = o.id
WHERE u.azure_oid = 'e1548f12-3f88-4a2c-aca4-2949b43b5d68';
```

**Expected Result:**
```
email: enterprise2.viewer@dqproj.onmicrosoft.com
azure_oid: e1548f12-3f88-4a2c-aca4-2949b43b5d68
org: DQ Project
role: viewer
user_segment: customer
```

## Still Having Issues?

1. Check browser console for more detailed errors
2. Check Supabase logs: Dashboard → Logs → API
3. Verify `.env` file has correct values
4. Make sure you restarted dev server after changing `.env`
5. Try running `04_check_tables.sql` for full diagnosis

---

**TL;DR:**
1. Run `01_complete_auth_setup.sql` (if tables don't exist)
2. Run `05_quick_provision_user.sql` (to provision your user)
3. Refresh browser and try logging in again

Good luck! 🚀
