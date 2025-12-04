-- ============================================================================
-- Create First Organization and User
-- ============================================================================
-- This script creates your first organization and admin user.
-- Update the values below with your actual information.
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Your Organization
-- ============================================================================

-- Update these values with your organization details
INSERT INTO auth_organizations (name, display_name, type, status)
VALUES (
  'your-company',           -- Change this: URL-friendly name (e.g., 'acme-corp')
  'Your Company Name',      -- Change this: Display name (e.g., 'Acme Corporation')
  'staff',                  -- Options: 'staff', 'partner', 'enterprise', 'advisor'
  'Active'                  -- Options: 'Active', 'Inactive', 'Suspended'
)
ON CONFLICT (name) DO NOTHING
RETURNING id, name, display_name;

-- ============================================================================
-- STEP 2: Create Your First User
-- ============================================================================

-- IMPORTANT: You'll need to update azure_oid after first login attempt
-- For now, we'll create the user without it, then update it later

-- Update these values with your user details
INSERT INTO auth_users (email, name, is_active)
VALUES (
  'your.email@example.com',  -- Change this: Your Azure AD email
  'Your Full Name',          -- Change this: Your name
  true
)
ON CONFLICT (email) DO NOTHING
RETURNING id, email, name;

-- ============================================================================
-- STEP 3: Create User Profile (Link User to Organization)
-- ============================================================================

-- This creates an admin profile for your user in your organization
-- Update the email to match the one you used above
INSERT INTO auth_user_profiles (user_id, organization_id, role, user_segment)
SELECT 
  u.id as user_id,
  o.id as organization_id,
  'admin' as role,           -- Options: 'admin', 'approver', 'creator', 'contributor', 'viewer'
  'internal' as user_segment -- Options: 'internal', 'partner', 'customer', 'advisor'
FROM auth_users u
CROSS JOIN auth_organizations o
WHERE u.email = 'your.email@example.com'  -- Change this: Match your email above
  AND o.name = 'your-company'             -- Change this: Match your org name above
ON CONFLICT (user_id, organization_id) DO NOTHING
RETURNING id, user_id, organization_id, role, user_segment;

-- ============================================================================
-- STEP 4: Verify Setup
-- ============================================================================

-- Check what was created
SELECT 
  'Organization' as type,
  o.name as identifier,
  o.display_name as name,
  o.type as role_or_type,
  o.status as status
FROM auth_organizations o
WHERE o.name = 'your-company'  -- Change this: Match your org name

UNION ALL

SELECT 
  'User' as type,
  u.email as identifier,
  u.name as name,
  CASE WHEN u.azure_oid IS NOT NULL THEN 'Has Azure OID' ELSE 'Missing Azure OID' END as role_or_type,
  CASE WHEN u.is_active THEN 'Active' ELSE 'Inactive' END as status
FROM auth_users u
WHERE u.email = 'your.email@example.com'  -- Change this: Match your email

UNION ALL

SELECT 
  'Profile' as type,
  u.email as identifier,
  o.display_name as name,
  p.role as role_or_type,
  p.user_segment as status
FROM auth_user_profiles p
JOIN auth_users u ON p.user_id = u.id
JOIN auth_organizations o ON p.organization_id = o.id
WHERE u.email = 'your.email@example.com';  -- Change this: Match your email

-- ============================================================================
-- NEXT STEPS
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ User created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE '📝 IMPORTANT: You still need to add your Azure OID';
  RAISE NOTICE '';
  RAISE NOTICE 'To get your Azure OID:';
  RAISE NOTICE '  1. Try logging in to your app';
  RAISE NOTICE '  2. Check browser console for: "Azure token verified"';
  RAISE NOTICE '  3. Copy the azureOid value';
  RAISE NOTICE '  4. OR decode your Azure JWT at https://jwt.io and look for "oid" claim';
  RAISE NOTICE '';
  RAISE NOTICE 'Then run this command (replace with your actual values):';
  RAISE NOTICE '';
  RAISE NOTICE '  UPDATE auth_users';
  RAISE NOTICE '  SET azure_oid = ''your-actual-azure-oid-here''';
  RAISE NOTICE '  WHERE email = ''your.email@example.com'';';
  RAISE NOTICE '';
  RAISE NOTICE 'Example Azure OID: a1b2c3d4-e5f6-7890-abcd-ef1234567890';
END $$;

-- ============================================================================
-- TEMPLATE: Update Azure OID (Run this after getting your OID)
-- ============================================================================

-- Uncomment and update these lines after you get your Azure OID:

-- UPDATE auth_users 
-- SET azure_oid = 'your-actual-azure-oid-from-token'
-- WHERE email = 'your.email@example.com';

-- Verify the update:
-- SELECT id, email, name, azure_oid, is_active 
-- FROM auth_users 
-- WHERE email = 'your.email@example.com';
