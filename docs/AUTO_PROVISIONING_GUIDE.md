# Auto-Provisioning Configuration Guide

## Overview

By default, users must be manually provisioned by an administrator. However, you can enable **auto-provisioning** to automatically create user accounts on first login.

## Security Considerations

### Manual Provisioning (Default - Recommended)
✅ **Pros:**
- Maximum security - admin controls all access
- Explicit role assignment
- Audit trail of who was granted access
- Prevents unauthorized users

❌ **Cons:**
- Requires manual SQL for each user
- Users can't self-register
- Admin overhead

### Auto-Provisioning (Optional)
✅ **Pros:**
- Users automatically created on first login
- No manual SQL required
- Faster onboarding
- Good for trusted Azure AD tenants

❌ **Cons:**
- Anyone in your Azure AD can access the system
- All users get the same default role initially
- Less control over who gets access

## Enable Auto-Provisioning

### Step 1: Update Environment Variables

Add these to your `.env` file:

```bash
# Enable auto-provisioning
VITE_AUTO_PROVISION_USERS=true

# Default organization for new users
VITE_DEFAULT_ORG_NAME=dqproj

# Default role for new users
# Options: admin, approver, creator, contributor, viewer
VITE_DEFAULT_USER_ROLE=viewer

# Default user segment for new users
# Options: internal, partner, customer, advisor
VITE_DEFAULT_USER_SEGMENT=customer
```

### Step 2: Create Default Organization

Run this in Supabase SQL Editor:

```sql
-- Create the default organization
INSERT INTO auth_organizations (name, display_name, type, status)
VALUES (
  'dqproj',           -- Must match VITE_DEFAULT_ORG_NAME
  'DQ Project',
  'staff',
  'Active'
)
ON CONFLICT (name) DO NOTHING;
```

### Step 3: Restart Your Dev Server

```bash
# Stop the server (Ctrl+C)
# Start it again
npm run dev
```

### Step 4: Test Auto-Provisioning

1. Try logging in with a new Azure AD user
2. Check browser console - you should see:
   ```
   🔄 Auto-provisioning new user: user@example.com
   ✅ User auto-provisioned successfully: { email: '...', role: 'viewer', segment: 'customer' }
   ```
3. User should be logged in automatically!

## Verify Auto-Provisioned Users

Check what users were created:

```sql
SELECT 
  u.email,
  u.name,
  u.azure_oid,
  o.display_name as organization,
  p.role,
  p.user_segment,
  u.created_at
FROM auth_users u
JOIN auth_user_profiles p ON u.id = p.user_id
JOIN auth_organizations o ON p.organization_id = o.id
ORDER BY u.created_at DESC;
```

## Change User Roles After Auto-Provisioning

Auto-provisioned users get the default role. To upgrade them:

```sql
-- Upgrade a user to admin
UPDATE auth_user_profiles
SET role = 'admin',
    user_segment = 'internal'
WHERE user_id = (
  SELECT id FROM auth_users WHERE email = 'user@example.com'
);

-- Verify the change
SELECT 
  u.email,
  p.role,
  p.user_segment
FROM auth_users u
JOIN auth_user_profiles p ON u.id = p.user_id
WHERE u.email = 'user@example.com';
```

## Disable Auto-Provisioning

To go back to manual provisioning:

```bash
# In .env file
VITE_AUTO_PROVISION_USERS=false

# Or remove the line entirely (default is false)
```

Then restart your dev server.

## Hybrid Approach (Recommended)

**Best of both worlds:**

1. **Enable auto-provisioning** with `viewer` role
2. **Manually upgrade** trusted users to higher roles

This way:
- New users can access the system immediately (as viewers)
- Admins can upgrade specific users to admin/approver roles
- You maintain control over who has elevated permissions

### Configuration for Hybrid:

```bash
# .env
VITE_AUTO_PROVISION_USERS=true
VITE_DEFAULT_USER_ROLE=viewer        # Start everyone as viewer
VITE_DEFAULT_USER_SEGMENT=customer   # Default segment
```

### Upgrade Script:

```sql
-- Upgrade specific users to admin
UPDATE auth_user_profiles
SET role = 'admin',
    user_segment = 'internal'
WHERE user_id IN (
  SELECT id FROM auth_users 
  WHERE email IN (
    'admin1@example.com',
    'admin2@example.com'
  )
);
```

## Environment Variables Reference

| Variable | Required | Default | Options |
|----------|----------|---------|---------|
| `VITE_AUTO_PROVISION_USERS` | No | `false` | `true`, `false` |
| `VITE_DEFAULT_ORG_NAME` | If auto-provision | `default-org` | Any org name |
| `VITE_DEFAULT_USER_ROLE` | If auto-provision | `viewer` | `admin`, `approver`, `creator`, `contributor`, `viewer` |
| `VITE_DEFAULT_USER_SEGMENT` | If auto-provision | `customer` | `internal`, `partner`, `customer`, `advisor` |

## Troubleshooting

### "Auto-provision failed"

**Check:**
1. Default organization exists in database
2. `VITE_DEFAULT_ORG_NAME` matches organization name exactly
3. Service role key has INSERT permissions
4. Restart dev server after changing `.env`

### Users created but can't log in

**Check:**
1. User profile was created (check `auth_user_profiles` table)
2. User is marked as `is_active = true`
3. Organization status is `Active`

### Want to delete auto-provisioned test users

```sql
-- Delete a specific user (cascades to profile)
DELETE FROM auth_users 
WHERE email = 'test@example.com';

-- Delete all users from a specific org
DELETE FROM auth_users
WHERE id IN (
  SELECT user_id FROM auth_user_profiles
  WHERE organization_id = (
    SELECT id FROM auth_organizations WHERE name = 'test-org'
  )
);
```

## Recommendations

### For Development:
- ✅ Enable auto-provisioning
- ✅ Use `viewer` as default role
- ✅ Manually upgrade your admin account

### For Production:
- ⚠️ Consider manual provisioning for maximum security
- ⚠️ If using auto-provision, monitor new user creation
- ⚠️ Set up alerts for new user registrations
- ⚠️ Regularly audit user roles and permissions

## Current Status

**Your current setup:** Manual provisioning (default)

**To enable auto-provisioning:** Follow Step 1-3 above

**To provision current user manually:** Run `database/migrations/05_quick_provision_user.sql`
