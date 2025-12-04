# User Provisioning: Manual vs Auto

## Quick Answer

**Right now:** You need to manually run the SQL script to provision users.

**Why:** Security - prevents unauthorized access to your system.

**Options:** You can enable auto-provisioning if you want users to be created automatically on first login.

---

## 🔒 Option 1: Manual Provisioning (Current - Default)

### How It Works
1. User tries to log in with Azure
2. Gets "user not provisioned" error
3. **Admin runs SQL script** to add them
4. User tries again and succeeds

### To Provision Your Current User

**Run this in Supabase SQL Editor:**

```bash
# Open: database/migrations/05_quick_provision_user.sql
# Copy all contents
# Paste into Supabase Dashboard → SQL Editor
# Click Run
```

### To Provision Additional Users

Use the template in `database/migrations/03_add_more_users.sql`

### Pros & Cons

✅ **Pros:**
- Maximum security
- Admin controls who gets access
- Explicit role assignment
- Audit trail

❌ **Cons:**
- Requires manual SQL for each user
- Users can't self-register
- Admin overhead

---

## 🚀 Option 2: Auto-Provisioning (Optional)

### How It Works
1. User tries to log in with Azure
2. System automatically creates their account
3. User gets default role (e.g., viewer)
4. User is logged in immediately

### To Enable Auto-Provisioning

**1. Add to `.env`:**
```bash
# Enable auto-provisioning
VITE_AUTO_PROVISION_USERS=true

# Default settings for new users
VITE_DEFAULT_ORG_NAME=dqproj
VITE_DEFAULT_USER_ROLE=viewer
VITE_DEFAULT_USER_SEGMENT=customer
```

**2. Create default organization (if not exists):**
```sql
-- Run in Supabase SQL Editor
INSERT INTO auth_organizations (name, display_name, type, status)
VALUES ('dqproj', 'DQ Project', 'staff', 'Active')
ON CONFLICT (name) DO NOTHING;
```

**3. Restart dev server:**
```bash
npm run dev
```

**4. Test:** Try logging in - user should be created automatically!

### Pros & Cons

✅ **Pros:**
- Users automatically created on first login
- No manual SQL required
- Faster onboarding
- Good for trusted Azure AD tenants

❌ **Cons:**
- Anyone in your Azure AD can access
- All users get same default role
- Less control over access

---

## 🎯 Recommended: Hybrid Approach

**Best of both worlds:**

1. Enable auto-provisioning with `viewer` role (read-only)
2. Manually upgrade trusted users to higher roles

### Configuration

```bash
# .env
VITE_AUTO_PROVISION_USERS=true
VITE_DEFAULT_USER_ROLE=viewer        # Everyone starts as viewer
VITE_DEFAULT_USER_SEGMENT=customer
```

### Upgrade Users

```sql
-- Upgrade specific users to admin
UPDATE auth_user_profiles
SET role = 'admin',
    user_segment = 'internal'
WHERE user_id = (
  SELECT id FROM auth_users WHERE email = 'admin@example.com'
);
```

### Benefits

- ✅ New users can access immediately (as viewers)
- ✅ Admins control who gets elevated permissions
- ✅ No manual provisioning for every user
- ✅ Security maintained for sensitive operations

---

## 📊 Comparison Table

| Feature | Manual | Auto | Hybrid |
|---------|--------|------|--------|
| **Security** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Ease of Use** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Admin Control** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **User Experience** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Setup Complexity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎬 What Should You Do Right Now?

### For Immediate Access (Manual)

**Run this SQL script:**
```bash
database/migrations/05_quick_provision_user.sql
```

This will provision the user that's trying to log in right now:
- Email: `enterprise2.viewer@dqproj.onmicrosoft.com`
- Azure OID: `e1548f12-3f88-4a2c-aca4-2949b43b5d68`
- Role: `viewer`

### For Future Users (Auto)

**Enable auto-provisioning:**
1. Add config to `.env` (see Option 2 above)
2. Create default organization
3. Restart dev server
4. All future users will be auto-created

---

## 📚 Documentation

- **Auto-Provisioning Guide:** `docs/AUTO_PROVISIONING_GUIDE.md`
- **Manual Provisioning:** `database/migrations/03_add_more_users.sql`
- **Quick Fix:** `FIX_406_ERROR.md`

---

## ❓ FAQ

**Q: Is auto-provisioning secure?**
A: Yes, if your Azure AD is properly configured. Only users in your Azure AD tenant can log in. However, manual provisioning gives you more control.

**Q: Can I change from manual to auto later?**
A: Yes! Just update `.env` and restart. Existing users are unaffected.

**Q: What if I want some users auto-provisioned and others manual?**
A: Use the hybrid approach - auto-provision as viewers, manually upgrade to higher roles.

**Q: Can I customize the auto-provisioning logic?**
A: Yes! The code is in `src/lib/federatedAuthSupabase.ts`. You can add custom logic based on email domain, Azure groups, etc.

---

## 🚦 Decision Guide

**Choose Manual if:**
- You have a small team
- You want maximum security
- You're okay with SQL provisioning
- You need explicit approval for each user

**Choose Auto if:**
- You have many users
- Your Azure AD is well-managed
- You trust everyone in your tenant
- You want frictionless onboarding

**Choose Hybrid if:**
- You want both security and convenience
- You have different user tiers
- You want to test before granting full access
- **This is recommended for most cases**

---

**Need help deciding?** The hybrid approach is usually the best choice!
