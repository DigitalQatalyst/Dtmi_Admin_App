-- ============================================================================
-- Add Additional Users to Your Organization
-- ============================================================================
-- Use this template to add more users after your first admin user is set up.
-- ============================================================================

-- ============================================================================
-- STEP 1: Create New User
-- ============================================================================

-- Update these values for each new user
INSERT INTO auth_users (email, name, is_active)
VALUES (
  'newuser@example.com',     -- Change this: User's Azure AD email
  'New User Name',           -- Change this: User's full name
  true
)
ON CONFLICT (email) DO UPDATE 
SET name = EXCLUDED.name,
    is_active = EXCLUDED.is_active
RETURNING id, email, name;

-- ============================================================================
-- STEP 2: Create User Profile
-- ============================================================================

-- Link the new user to your organization with appropriate role
INSERT INTO auth_user_profiles (user_id, organization_id, role, user_segment)
SELECT 
  u.id as user_id,
  o.id as organization_id,
  'viewer' as role,          -- Change this: 'admin', 'approver', 'creator', 'contributor', 'viewer'
  'internal' as user_segment -- Change this: 'internal', 'partner', 'customer', 'advisor'
FROM auth_users u
CROSS JOIN auth_organizations o
WHERE u.email = 'newuser@example.com'  -- Change this: Match email above
  AND o.name = 'your-company'          -- Change this: Your organization name
ON CONFLICT (user_id, organization_id) DO UPDATE
SET role = EXCLUDED.role,
    user_segment = EXCLUDED.user_segment
RETURNING id, user_id, organization_id, role, user_segment;

-- ============================================================================
-- STEP 3: Update Azure OID (After First Login)
-- ============================================================================

-- After the user logs in for the first time, update their Azure OID
-- Get the OID from browser console or by decoding their JWT token

-- UPDATE auth_users 
-- SET azure_oid = 'user-azure-oid-from-token'
-- WHERE email = 'newuser@example.com';

-- ============================================================================
-- STEP 4: Verify User Setup
-- ============================================================================

SELECT 
  u.email,
  u.name,
  u.azure_oid,
  u.is_active,
  o.display_name as organization,
  p.role,
  p.user_segment
FROM auth_users u
JOIN auth_user_profiles p ON u.id = p.user_id
JOIN auth_organizations o ON p.organization_id = o.id
WHERE u.email = 'newuser@example.com';  -- Change this: Match email above

-- ============================================================================
-- BULK USER CREATION (Optional)
-- ============================================================================

-- If you need to create multiple users at once, use this template:

/*
-- Create multiple users
INSERT INTO auth_users (email, name, is_active)
VALUES 
  ('user1@example.com', 'User One', true),
  ('user2@example.com', 'User Two', true),
  ('user3@example.com', 'User Three', true)
ON CONFLICT (email) DO NOTHING;

-- Create profiles for all new users
INSERT INTO auth_user_profiles (user_id, organization_id, role, user_segment)
SELECT 
  u.id,
  o.id,
  'viewer' as role,
  'internal' as user_segment
FROM auth_users u
CROSS JOIN auth_organizations o
WHERE u.email IN ('user1@example.com', 'user2@example.com', 'user3@example.com')
  AND o.name = 'your-company'
ON CONFLICT (user_id, organization_id) DO NOTHING;

-- Verify all users
SELECT 
  u.email,
  u.name,
  o.display_name as organization,
  p.role,
  p.user_segment,
  CASE WHEN u.azure_oid IS NOT NULL THEN '✅ Has OID' ELSE '⚠️ Missing OID' END as azure_status
FROM auth_users u
JOIN auth_user_profiles p ON u.id = p.user_id
JOIN auth_organizations o ON p.organization_id = o.id
WHERE u.email IN ('user1@example.com', 'user2@example.com', 'user3@example.com')
ORDER BY u.email;
*/

-- ============================================================================
-- ROLE REFERENCE
-- ============================================================================

/*
Available Roles:
- admin:       Full access to everything
- approver:    Can approve content and manage workflows
- creator:     Can create and edit content (normalized to 'editor' in frontend)
- contributor: Can contribute content (normalized to 'editor' in frontend)
- viewer:      Read-only access

Available User Segments:
- internal:  Staff members (full access to internal features)
- partner:   Partner organizations (limited access)
- customer:  Enterprise customers (customer-facing features)
- advisor:   External advisors (advisory features)
*/

-- ============================================================================
-- UPDATE USER ROLE (If needed)
-- ============================================================================

-- To change a user's role or segment:
/*
UPDATE auth_user_profiles
SET role = 'admin',           -- New role
    user_segment = 'internal' -- New segment
WHERE user_id = (SELECT id FROM auth_users WHERE email = 'user@example.com')
  AND organization_id = (SELECT id FROM auth_organizations WHERE name = 'your-company');
*/

-- ============================================================================
-- DEACTIVATE USER (If needed)
-- ============================================================================

-- To deactivate a user (they won't be able to log in):
/*
UPDATE auth_users
SET is_active = false
WHERE email = 'user@example.com';
*/

-- To reactivate:
/*
UPDATE auth_users
SET is_active = true
WHERE email = 'user@example.com';
*/
