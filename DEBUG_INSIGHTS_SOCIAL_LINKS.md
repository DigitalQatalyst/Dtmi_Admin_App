# Debugging Guide: Insights & Social Links Not Loading

## Issue
The insights and social media links are not being fetched when editing content.

## Debug Steps

### 1. Check Browser Console
Open the browser console (F12) and look for these debug messages:

**When loading content for editing:**
```
[DEBUG] Metadata loaded: {
  hasInsights: true/false,
  insightsCount: 0,
  insights: [...],
  authorEmail: "...",
  authorTwitter: "...",
  authorInstagram: "..."
}
```

**When saving content:**
```
[DEBUG] Saving metadata (CREATE/UPDATE): {
  hasInsights: true/false,
  insightsCount: 0,
  insights: [...],
  authorEmail: "...",
  authorTwitter: "...",
  authorInstagram: "..."
}
```

### 2. Check Database Directly

Run this query in Supabase SQL Editor:

```sql
-- Check if data is being saved
SELECT 
  id,
  title,
  metadata->>'author_email' as email,
  metadata->>'author_twitter' as twitter,
  metadata->>'author_instagram' as instagram,
  metadata->'insights' as insights,
  metadata
FROM cnt_contents
WHERE id = 'YOUR_CONTENT_ID'
LIMIT 1;
```

### 3. Verify Data is Being Saved

**Test Create:**
1. Create new content
2. Add insights: "Test insight 1", "Test insight 2"
3. Add email: test@example.com
4. Add Twitter: @testuser
5. Add Instagram: @testuser
6. Save
7. Check console for "[DEBUG] Saving metadata (CREATE)"
8. Run the SQL query above with the new content ID

**Test Update:**
1. Edit existing content
2. Check console for "[DEBUG] Metadata loaded"
3. Modify insights/social links
4. Save
5. Check console for "[DEBUG] Saving metadata (UPDATE)"
6. Reload the page and check if data persists

### 4. Common Issues & Solutions

#### Issue: Metadata is null or empty
**Solution:** The content might have been created before we added these fields.
- Create new content to test
- Or manually update the database:

```sql
UPDATE cnt_contents
SET metadata = jsonb_set(
  COALESCE(metadata, '{}'::jsonb),
  '{insights}',
  '["Test insight 1", "Test insight 2"]'::jsonb
)
WHERE id = 'YOUR_CONTENT_ID';

UPDATE cnt_contents
SET metadata = jsonb_set(
  COALESCE(metadata, '{}'::jsonb),
  '{author_email}',
  '"test@example.com"'::jsonb
)
WHERE id = 'YOUR_CONTENT_ID';
```

#### Issue: Data saves but doesn't load
**Check the fetch query:**
```javascript
// In browser console, check what's being fetched
const { data } = await supabase
  .from('cnt_contents')
  .select('*, metadata')
  .eq('id', 'YOUR_CONTENT_ID')
  .single();

console.log('Fetched data:', data);
console.log('Metadata:', data.metadata);
console.log('Insights:', data.metadata?.insights);
```

#### Issue: Metadata is a string instead of object
**This is handled in the code, but verify:**
```javascript
// The code handles both cases:
if (typeof rawMeta === 'string') {
  metadata = JSON.parse(rawMeta);
} else {
  metadata = rawMeta || {};
}
```

### 5. Manual Test in Browser Console

Open browser console on the content form page and run:

```javascript
// Check current form data
console.log('Current formData:', window.__formData);

// Or access via React DevTools
// Find the MediaContentForm component and check its state
```

### 6. Verify Form State

Add temporary logging in the component:

```javascript
// In BasicInformationSection.tsx
useEffect(() => {
  console.log('[BasicInfo] Insights:', formData.insights);
}, [formData.insights]);

// In AuthorDetailsSection.tsx
useEffect(() => {
  console.log('[AuthorDetails] Social links:', {
    email: formData.authorEmail,
    twitter: formData.authorTwitter,
    instagram: formData.authorInstagram,
  });
}, [formData.authorEmail, formData.authorTwitter, formData.authorInstagram]);
```

## Expected Behavior

### On Create:
1. User fills insights and social links
2. Console shows: `[DEBUG] Saving metadata (CREATE)` with the data
3. Data is saved to `cnt_contents.metadata`
4. Success message appears

### On Edit:
1. Form loads existing content
2. Console shows: `[DEBUG] Metadata loaded` with the data
3. Insights appear in the list
4. Social links populate in the input fields
5. User can modify and save

### On Reload After Save:
1. Navigate to edit the same content
2. Console shows: `[DEBUG] Metadata loaded`
3. All insights and social links should be populated

## Quick Fix Checklist

- [ ] Check browser console for debug messages
- [ ] Verify data in database using SQL query
- [ ] Test with NEW content (not old content)
- [ ] Check if metadata is being saved (SQL query)
- [ ] Check if metadata is being loaded (console logs)
- [ ] Verify form fields are bound correctly
- [ ] Check for JavaScript errors in console

## Contact Points

If data is:
- ✅ Saving correctly (SQL shows data) but ❌ Not loading → Issue in fetch/parse logic
- ❌ Not saving (SQL shows null) but ✅ Form has data → Issue in save logic
- ❌ Not in form state but ✅ In database → Issue in form binding

## Next Steps

1. Run through the debug steps above
2. Share the console output from the debug messages
3. Share the SQL query results
4. We can then pinpoint the exact issue
