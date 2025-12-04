-- ============================================================================
-- Complete Authentication Setup for New Supabase Project
-- ============================================================================
-- This script sets up all authentication tables, indexes, RLS policies,
-- and helper functions needed for Azure Entra ID federated identity.
--
-- Run this script ONCE in your new Supabase project via SQL Editor.
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- STEP 1: Create Organizations Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS auth_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_name TEXT,
  type TEXT DEFAULT 'staff' CHECK (type IN ('staff', 'partner', 'enterprise', 'advisor')),
  status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_auth_organizations_name ON auth_organizations(name);
CREATE INDEX IF NOT EXISTS idx_auth_organizations_status ON auth_organizations(status);

-- Add comments
COMMENT ON TABLE auth_organizations IS 'Organizations/tenants in the system';
COMMENT ON COLUMN auth_organizations.name IS 'Unique organization identifier (slug)';
COMMENT ON COLUMN auth_organizations.display_name IS 'Human-readable organization name';
COMMENT ON COLUMN auth_organizations.type IS 'Organization type: staff, partner, enterprise, or advisor';

-- ============================================================================
-- STEP 2: Create Users Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS auth_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  azure_oid TEXT UNIQUE, -- PRIMARY: Azure Object ID (stable across app registrations)
  azure_sub TEXT,        -- LEGACY: Azure Subject (app-specific, for compatibility)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_azure_oid ON auth_users(azure_oid) WHERE azure_oid IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auth_users_azure_sub ON auth_users(azure_sub) WHERE azure_sub IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auth_users_email ON auth_users(email);
CREATE INDEX IF NOT EXISTS idx_auth_users_active ON auth_users(is_active);

-- Add comments
COMMENT ON TABLE auth_users IS 'User accounts with Azure federated identity';
COMMENT ON COLUMN auth_users.azure_oid IS 'Azure AD Object ID (oid claim) - PRIMARY federated identifier. Stable across all app registrations.';
COMMENT ON COLUMN auth_users.azure_sub IS 'Azure AD Subject (sub claim) - app-specific. Kept for legacy compatibility only.';
COMMENT ON COLUMN auth_users.email IS 'User email address from Azure AD';

-- ============================================================================
-- STEP 3: Create User Profiles Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS auth_user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES auth_organizations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'approver', 'creator', 'contributor', 'viewer')),
  user_segment TEXT NOT NULL CHECK (user_segment IN ('internal', 'partner', 'customer', 'advisor')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, organization_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_auth_user_profiles_user_id ON auth_user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_user_profiles_org_id ON auth_user_profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_auth_user_profiles_role ON auth_user_profiles(role);

-- Add comments
COMMENT ON TABLE auth_user_profiles IS 'User roles and permissions per organization';
COMMENT ON COLUMN auth_user_profiles.role IS 'User role: admin, approver, creator, contributor, or viewer';
COMMENT ON COLUMN auth_user_profiles.user_segment IS 'User segment: internal (staff), partner, customer, or advisor';
COMMENT ON COLUMN auth_user_profiles.metadata IS 'Additional user metadata (JSON)';

-- ============================================================================
-- STEP 4: Enable Row Level Security (RLS)
-- ============================================================================

ALTER TABLE auth_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 5: Create Helper Functions for Authorization
-- ============================================================================

-- Function to get current organization ID from app context
CREATE OR REPLACE FUNCTION get_app_organization_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Try to get from app context variable (set by backend)
  IF current_setting('app.organization_id', true) IS NOT NULL THEN
    RETURN current_setting('app.organization_id', true)::uuid;
  END IF;
  
  -- Fallback to auth_user_profiles lookup
  RETURN (
    SELECT organization_id 
    FROM auth_user_profiles 
    WHERE user_id = auth.uid()
    LIMIT 1
  );
END;
$$;

-- Function to get current user role
CREATE OR REPLACE FUNCTION get_app_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Try to get from app context variable
  IF current_setting('app.user_role', true) IS NOT NULL THEN
    RETURN current_setting('app.user_role', true);
  END IF;
  
  -- Fallback to auth_user_profiles lookup
  RETURN (
    SELECT role 
    FROM auth_user_profiles 
    WHERE user_id = auth.uid()
    LIMIT 1
  );
END;
$$;

-- Function to get current customer type (user segment)
CREATE OR REPLACE FUNCTION get_app_customer_type()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Try to get from app context variable
  IF current_setting('app.customer_type', true) IS NOT NULL THEN
    RETURN current_setting('app.customer_type', true);
  END IF;
  
  -- Fallback to auth_user_profiles lookup
  RETURN (
    SELECT user_segment 
    FROM auth_user_profiles 
    WHERE user_id = auth.uid()
    LIMIT 1
  );
END;
$$;

-- Add comments
COMMENT ON FUNCTION get_app_organization_id() IS 'Returns the current user organization ID from app context or database lookup';
COMMENT ON FUNCTION get_app_user_role() IS 'Returns the current user role from app context or database lookup';
COMMENT ON FUNCTION get_app_customer_type() IS 'Returns the current user customer type from app context or database lookup';

-- ============================================================================
-- STEP 6: Create RLS Policies
-- ============================================================================

-- Organizations: Users can view their own organization
DROP POLICY IF EXISTS "Users can view their organization" ON auth_organizations;
CREATE POLICY "Users can view their organization" ON auth_organizations
  FOR SELECT
  USING (
    id IN (
      SELECT organization_id 
      FROM auth_user_profiles 
      WHERE user_id = auth.uid()
    )
  );

-- Users: Users can view themselves and users in their organization
DROP POLICY IF EXISTS "Users can view themselves" ON auth_users;
CREATE POLICY "Users can view themselves" ON auth_users
  FOR SELECT
  USING (
    id = auth.uid() OR
    id IN (
      SELECT user_id 
      FROM auth_user_profiles 
      WHERE organization_id IN (
        SELECT organization_id 
        FROM auth_user_profiles 
        WHERE user_id = auth.uid()
      )
    )
  );

-- User Profiles: Users can view profiles in their organization
DROP POLICY IF EXISTS "Users can view profiles in their org" ON auth_user_profiles;
CREATE POLICY "Users can view profiles in their org" ON auth_user_profiles
  FOR SELECT
  USING (
    user_id = auth.uid() OR
    organization_id IN (
      SELECT organization_id 
      FROM auth_user_profiles 
      WHERE user_id = auth.uid()
    )
  );

-- User Profiles: Users can update their own profile metadata
DROP POLICY IF EXISTS "Users can update their own profile" ON auth_user_profiles;
CREATE POLICY "Users can update their own profile" ON auth_user_profiles
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- STEP 7: Create Updated At Triggers
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to all tables
DROP TRIGGER IF EXISTS update_auth_organizations_updated_at ON auth_organizations;
CREATE TRIGGER update_auth_organizations_updated_at
  BEFORE UPDATE ON auth_organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_auth_users_updated_at ON auth_users;
CREATE TRIGGER update_auth_users_updated_at
  BEFORE UPDATE ON auth_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_auth_user_profiles_updated_at ON auth_user_profiles;
CREATE TRIGGER update_auth_user_profiles_updated_at
  BEFORE UPDATE ON auth_user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 8: Grant Permissions
-- ============================================================================

-- Grant service role full access (for backend API)
GRANT ALL ON auth_organizations TO service_role;
GRANT ALL ON auth_users TO service_role;
GRANT ALL ON auth_user_profiles TO service_role;

-- Grant authenticated users read access (RLS will filter)
GRANT SELECT ON auth_organizations TO authenticated;
GRANT SELECT ON auth_users TO authenticated;
GRANT SELECT, UPDATE ON auth_user_profiles TO authenticated;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================

-- Verify tables were created
SELECT 
  'auth_organizations' as table_name,
  COUNT(*) as row_count
FROM auth_organizations
UNION ALL
SELECT 
  'auth_users' as table_name,
  COUNT(*) as row_count
FROM auth_users
UNION ALL
SELECT 
  'auth_user_profiles' as table_name,
  COUNT(*) as row_count
FROM auth_user_profiles;

-- Show RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('auth_organizations', 'auth_users', 'auth_user_profiles')
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Authentication setup complete!';
  RAISE NOTICE '📝 Next steps:';
  RAISE NOTICE '   1. Run 02_create_first_user.sql to create your first organization and user';
  RAISE NOTICE '   2. Get your Azure OID from first login attempt';
  RAISE NOTICE '   3. Update the user with your actual Azure OID';
  RAISE NOTICE '   4. Test the login flow';
END $$;
