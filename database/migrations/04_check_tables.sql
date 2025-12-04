-- ============================================================================
-- Check if Auth Tables Exist in Your New Supabase Project
-- ============================================================================
-- Run this in Supabase SQL Editor to verify your setup
-- ============================================================================

-- Check if tables exist
SELECT 
  table_name,
  CASE 
    WHEN table_name IN (
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public'
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (
  VALUES 
    ('auth_organizations'),
    ('auth_users'),
    ('auth_user_profiles')
) AS t(table_name);

-- If tables exist, check their structure
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'auth_users') THEN
    RAISE NOTICE '✅ auth_users table exists';
    RAISE NOTICE 'Columns:';
  ELSE
    RAISE NOTICE '❌ auth_users table does NOT exist - you need to run 01_complete_auth_setup.sql';
  END IF;
END $$;

-- Show auth_users columns if table exists
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'auth_users'
ORDER BY ordinal_position;

-- Check if any users exist
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN azure_oid IS NOT NULL THEN 1 END) as users_with_oid,
  COUNT(CASE WHEN azure_oid IS NULL THEN 1 END) as users_without_oid
FROM auth_users;

-- Show all users (if any)
SELECT 
  id,
  email,
  name,
  azure_oid,
  is_active,
  created_at
FROM auth_users
ORDER BY created_at DESC;

-- Check RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('auth_organizations', 'auth_users', 'auth_user_profiles')
ORDER BY tablename;

-- Check if service_role has access
SELECT 
  grantee,
  table_name,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN ('auth_organizations', 'auth_users', 'auth_user_profiles')
  AND grantee IN ('service_role', 'authenticated', 'anon')
ORDER BY table_name, grantee;
