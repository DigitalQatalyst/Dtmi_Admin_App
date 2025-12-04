# Setup Guide: Migrate to New Supabase Project

This guide will help you set up authentication tables in your new Supabase project.

## Prerequisites

✅ You've updated `.env` with new Supabase credentials:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SUPABASE_SERVICE_ROLE_KEY`

## Quick Start (Recommended)

### Option 1: Using Supabase Dashboard (Easiest)

1. **Go to Supabase Dashboard**
   - Open your new project at https://supabase.com/dashboard
   - Click **SQL Editor** in the left sidebar

2. **Run the Complete Setup Script**
   - Click **New Query**
   - Copy and paste the contents of `01_complete_auth_setup.sql`
   - Click **Run** (or press Ctrl+Enter)
   - Wait for completion (should take ~10 seconds)

3. **Verify Tables Created**
   - Click **Table Editor** in the left sidebar
   - You should see:
     - `auth_organizations`
     - `auth_users`
     - `auth_user_profiles`

4. **Create Your First Organization and User**
   - Run the script in `02_create_first_user.sql`
   - Update the email and azure_oid values with your actual data

### Option 2: Using Command Line (psql)

```bash
# Get your connection string from Supabase Dashboard → Settings → Database
# It looks like: postgresql://postgres.[REF]:[PASSWORD]@aws-0-region.pooler.supabase.com:5432/postgres

# Connect to database
psql "your-connection-string-here"

# Run the setup script
\i database/migrations/01_complete_auth_setup.sql

# Create first user
\i database/migrations/02_create_first_user.sql
```

## What Gets Created

### Tables
1. **auth_organizations** - Organizations/tenants
2. **auth_users** - User accounts with Azure federated identity
3. **auth_user_profiles** - User roles and permissions per organization

### Indexes
- Fast lookups by `azure_oid` (primary federated identifier)
- Fast lookups by `email`
- Organization and user relationships

### RLS Policies
- Organization isolation (users only see their org's data)
- User profile access control
- Helper functions for authorization

### Functions
- `get_app_organization_id()` - Get current user's organization
- `get_app_user_role()` - Get current user's role
- `get_app_customer_type()` - Get current user's customer type

## After Setup

### 1. Get Azure OID for Your User

When you first log in with Azure, check the browser console for:
```
🔐 Azure token verified (authenticated only): {
  azureOid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  email: "your@email.com"
}
```

Or decode your Azure JWT token at https://jwt.io and look for the `oid` claim.

### 2. Update User with Azure OID

```sql
UPDATE auth_users 
SET azure_oid = 'your-actual-azure-oid-from-token'
WHERE email = 'your@email.com';
```

### 3. Test Login

```bash
# Start your backend
cd api
npm run dev

# Start your frontend (in another terminal)
npm run dev

# Visit http://localhost:3000 and try logging in
```

## Troubleshooting

### "User not provisioned" error
- Make sure you've created the user in `auth_users` table
- Make sure the `azure_oid` matches the one from your Azure token
- Make sure the user has a profile in `auth_user_profiles`

### "Invalid API key" error
- Double-check `VITE_SUPABASE_SERVICE_ROLE_KEY` in `.env`
- Make sure it's the **service_role** key, not the anon key
- Get it from Supabase Dashboard → Settings → API

### Tables not created
- Check for errors in the SQL Editor
- Make sure you're running the script in the correct project
- Try running each section separately

## Migration Files

- `01_complete_auth_setup.sql` - Complete setup (tables, indexes, RLS, functions)
- `02_create_first_user.sql` - Template for creating your first user
- `03_add_more_users.sql` - Template for adding additional users

## Next Steps

After successful setup:
1. ✅ Create your organization
2. ✅ Create your first admin user
3. ✅ Get Azure OID from first login attempt
4. ✅ Update user with Azure OID
5. ✅ Test login flow
6. ✅ Add more users as needed

## Need Help?

Check the main README: `database/migrations/README.md`
