-- ============================================================================
-- Quick User Provisioning Script
-- ============================================================================
-- This script provisions the user that's trying to log in right now
-- Azure OID: e1548f12-3f88-4a2c-aca4-2949b43b5d68
-- Email: enterprise2.viewer@dqproj.onmicrosoft.com
-- ============================================================================

-- STEP 1: Create organization (if it doesn't exist)
INSERT INTO auth_organizations (name, display_name, type, status)
VALUES (
  'dqproj',
  'DQ Project',
  'staff',
  'Active'
)
ON CONFLICT (name) DO NOTHING
RETURNING id, name, display_name;

-- STEP 2: Create the user with the Azure OID from the error
INSERT INTO auth_users (
  email, 
  name, 
  azure_oid,
  is_active
)
VALUES (
  'enterprise2.viewer@dqproj.onmicrosoft.com',
  'Enterprise Viewer',
  'e1548f12-3f88-4a2c-aca4-2949b43b5d68',
  true
)
ON CONFLICT (email) DO UPDATE 
SET azure_oid = EXCLUDED.azure_oid,
    name = EXCLUDED.name,
    is_active = EXCLUDED.is_active
RETURNING id, email, name, azure_oid;

-- STEP 3: Create user profile
INSERT INTO auth_user_profiles (user_id, organization_id, role, user_segment)
SELECT 
  u.id as user_id,
  o.id as organization_id,
  'viewer' as role,
  'customer' as user_segment
FROM auth_users u
CROSS JOIN auth_organizations o
WHERE u.email = 'enterprise2.viewer@dqproj.onmicrosoft.com'
  AND o.name = 'dqproj'
ON CONFLICT (user_id, organization_id) DO UPDATE
SET role = EXCLUDED.role,
    user_segment = EXCLUDED.user_segment
RETURNING id, user_id, organization_id, role, user_segment;

-- STEP 4: Verify the user was created
SELECT 
  u.id,
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
WHERE u.email = 'enterprise2.viewer@dqproj.onmicrosoft.com';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ User provisioned successfully!';
  RAISE NOTICE 'Email: enterprise2.viewer@dqproj.onmicrosoft.com';
  RAISE NOTICE 'Azure OID: e1548f12-3f88-4a2c-aca4-2949b43b5d68';
  RAISE NOTICE 'Role: viewer';
  RAISE NOTICE 'Segment: customer';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 Now try logging in again!';
END $$;
