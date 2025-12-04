# 🚀 Quick Start: Migrate to New Supabase Project

## ✅ Prerequisites Checklist

- [ ] Updated `.env` with new Supabase URL and keys
- [ ] Have access to new Supabase project dashboard
- [ ] Know your Azure AD email address
- [ ] Have Azure Entra ID app registration configured

## 📋 Step-by-Step Migration

### Step 1: Update Environment Variables (5 minutes)

Open your `.env` file and update these values:

```bash
# NEW Supabase Project
VITE_SUPABASE_URL=https://YOUR_NEW_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=your_new_anon_key
VITE_SUPABASE_SERVICE_ROLE_KEY=your_new_service_role_key

# Backend (same as above)
SUPABASE_URL=https://YOUR_NEW_PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_new_service_role_key
```

**Where to find these:**
- Go to Supabase Dashboard → Settings → API
- Copy `URL`, `anon public` key, and `service_role` key

### Step 2: Run Database Setup (2 minutes)

**Option A: Using Supabase Dashboard (Recommended)**

1. Open Supabase Dashboard → **SQL Editor**
2. Click **New Query**
3. Copy contents of `database/migrations/01_complete_auth_setup.sql`
4. Paste and click **Run** (or Ctrl+Enter)
5. Wait for "✅ Authentication setup complete!" message

**Option B: Using Command Line**

```bash
# Get connection string from Supabase Dashboard → Settings → Database
psql "your-connection-string"

# Run setup
\i database/migrations/01_complete_auth_setup.sql
```

### Step 3: Create Your First User (3 minutes)

1. Open `database/migrations/02_create_first_user.sql`
2. Update these values:
   ```sql
   -- Line 15: Your organization name
   'your-company' → 'acme-corp'
   
   -- Line 16: Your organization display name
   'Your Company Name' → 'Acme Corporation'
   
   -- Line 30: Your email
   'your.email@example.com' → 'john@acme.com'
   
   -- Line 31: Your name
   'Your Full Name' → 'John Doe'
   
   -- Line 44-45: Match your email and org name
   ```
3. Run the script in Supabase SQL Editor

### Step 4: Get Your Azure OID (2 minutes)

**Method 1: From First Login Attempt**
1. Start your app: `npm run dev`
2. Try to log in with Azure
3. Open browser console (F12)
4. Look for: `🔐 Azure token verified (authenticated only):`
5. Copy the `azureOid` value

**Method 2: Decode JWT Token**
1. Log in to Azure
2. Copy your JWT token from browser DevTools → Application → Local Storage
3. Go to https://jwt.io
4. Paste your token
5. Find the `oid` claim in the payload

### Step 5: Update User with Azure OID (1 minute)

Run this in Supabase SQL Editor:

```sql
UPDATE auth_users 
SET azure_oid = 'your-actual-azure-oid-here'
WHERE email = 'your.email@example.com';

-- Verify
SELECT id, email, name, azure_oid 
FROM auth_users 
WHERE email = 'your.email@example.com';
```

### Step 6: Test Login (2 minutes)

```bash
# Terminal 1: Start backend
cd api
npm install
npm run dev

# Terminal 2: Start frontend
npm run dev

# Browser: Visit http://localhost:3000
# Click login and authenticate with Azure
```

**Expected Console Logs:**
```
🔐 MSAL Configuration: { redirectUri: '...', clientId: 'Set', ... }
🔐 Got Azure ID token, getting authorization from Supabase...
✅ Received authorization context: { user_id: '...', role: 'admin', ... }
🎉 Federated identity login successful
```

## 🎉 Success!

If you see the dashboard after login, you're all set!

## 🔧 Troubleshooting

### "User not provisioned" Error
```sql
-- Check if user exists
SELECT * FROM auth_users WHERE email = 'your@email.com';

-- Check if profile exists
SELECT * FROM auth_user_profiles WHERE user_id = (
  SELECT id FROM auth_users WHERE email = 'your@email.com'
);

-- Check azure_oid is set
SELECT email, azure_oid FROM auth_users WHERE email = 'your@email.com';
```

### "Invalid API key" Error
- Double-check `VITE_SUPABASE_SERVICE_ROLE_KEY` in `.env`
- Make sure it's the **service_role** key (not anon key)
- Restart your dev server after changing `.env`

### "Redirect URI mismatch" Error
- Check `VITE_AZURE_REDIRECT_URI_CUSTOM` matches Azure app registration
- Must include protocol (http/https) and exact path
- No trailing slash unless Azure has it

### Tables Not Created
```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'auth_%';

-- Should show: auth_organizations, auth_users, auth_user_profiles
```

## 📚 Additional Resources

- **Complete Setup Guide**: `database/migrations/00_SETUP_NEW_PROJECT.md`
- **Add More Users**: `database/migrations/03_add_more_users.sql`
- **Migration Details**: `database/migrations/README.md`
- **IAM Documentation**: `docs/iam/README.md`

## 🆘 Need Help?

Common issues and solutions:
1. **Can't connect to Supabase**: Check URL and keys in `.env`
2. **Login fails**: Verify Azure OID is set correctly
3. **No permissions**: Check user role in `auth_user_profiles`
4. **RLS errors**: Make sure RLS policies were created

## ⏭️ Next Steps

After successful setup:
- [ ] Add more users: Use `03_add_more_users.sql`
- [ ] Configure Azure Entra ID for new project (if different tenant)
- [ ] Update production environment variables
- [ ] Test all authentication flows
- [ ] Set up additional content tables (if needed)

---

**Total Time: ~15 minutes** ⏱️

Good luck! 🚀
