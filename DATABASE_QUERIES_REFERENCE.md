# Database Queries Reference
## All Queries Used in the Admin App

This document details every database query used in your application to fetch and manage content.

---

## 📊 Query Overview

Your app uses **3 main data sources**:
1. `v_media_all` - View for listing content (optimized)
2. `cnt_contents` - Table for detailed content and metadata
3. Database functions (`create_media_item`, `update_media_item`)

---

## 🔍 Content List Queries

### Query 1: List All Content (Main Query)

**Location:** `src/services/knowledgehub.ts` → `listMedia()`

**Primary Query:**
```sql
SELECT * 
FROM v_media_all
WHERE 1=1
  AND (status = :status OR :status IS NULL)
  AND (type = :type OR :type = 'All')
  AND (domain = :domain OR :domain IS NULL)
  AND (
    title ILIKE '%:search%' 
    OR summary ILIKE '%:search%'
    OR :search IS NULL
  )
ORDER BY created_at DESC
LIMIT :limit;
```

**What it fetches:**
- All published/draft content
- Filtered by status, type, domain, search
- Ordered by creation date (newest first)
- Limited to specified number (default: 100)

**Fields returned from `v_media_all`:**
- `id` - Content ID
- `title` - Content title
- `summary` - Short description
- `type` - Content type (Article, Video, Podcast, etc.)
- `status` - Publication status
- `thumbnail_url` - Featured image
- `published_at` - Publication date
- `created_at` - Creation date
- `updated_at` - Last modified date
- `domain` - Category/domain
- `tags` - Array of tags
- `article_byline` - Author from metadata
- `article_body_html` - Article content (for Article types)
- `video_url` - Video URL (for Video types)
- `audio_url` - Audio URL (for Podcast types)
- And more type-specific fields...

---

### Query 2: Fetch Metadata for List Items

**Location:** `src/services/knowledgehub.ts` → `listMedia()`

**Secondary Query (runs after main query):**
```sql
SELECT 
  id, 
  metadata, 
  author_name
FROM cnt_contents
WHERE id IN (:id1, :id2, :id3, ...);
```

**Purpose:**
- Fetches full metadata for each content item
- Gets author_name from table (not just from view)
- Merges metadata back into the results

**What's in metadata:**
```json
{
  "author_name": "John Doe",
  "author_org": "Company Name",
  "author_title": "CEO",
  "author_bio": "Biography...",
  "author_photo_url": "https://...",
  "author_email": "john@example.com",
  "author_twitter": "@johndoe",
  "author_instagram": "@johndoe",
  "insights": ["Insight 1", "Insight 2", "Insight 3"],
  "toolkit": { ... }
}
```

---

## 📝 Single Content Queries

### Query 3: Fetch Single Content for Editing

**Location:** `src/components/media-content-form/hooks/useMediaContentFormController.ts`

**Query:**
```sql
SELECT *, metadata
FROM cnt_contents
WHERE id = :contentId;
```

**Purpose:**
- Loads full content details for editing
- Includes complete metadata object
- Used when opening edit form

**Additional queries for editing:**

**Query 3a: Fetch from View (for type-specific data)**
```sql
SELECT 
  slug,
  article_body_html,
  article_byline,
  article_source,
  video_url,
  video_duration_sec,
  audio_url,
  episode_no,
  is_video_episode,
  report_document_url,
  report_file_size_mb,
  tool_document_url,
  tool_file_size_mb,
  type,
  domain,
  authors,
  author_slugs
FROM v_media_all
WHERE id = :contentId;
```

**Query 3b: Fetch Taxonomy Facets (if enabled)**
```sql
-- RPC function call
SELECT * FROM get_content_facet_values(
  content_id := :contentId,
  language_code := 'en'
);
```

**Query 3c: Fetch Tags (if enabled)**
```sql
-- RPC function call
SELECT * FROM get_content_tags(
  content_id := :contentId
);
```

---

## ✍️ Content Creation/Update Queries

### Query 4: Create New Content

**Location:** `src/services/knowledgehub.ts` → `createMedia()`

**Query:**
```sql
-- RPC function call
SELECT create_media_item(
  _base := :basePayload,
  _type := :contentType,
  _child := :childPayload,
  _facet_value_ids := NULL,
  _tag_ids := NULL,
  _collection_ids := NULL,
  _user_id := NULL
);
```

**Base Payload Structure:**
```json
{
  "slug": "article-slug",
  "title": "Article Title",
  "summary": "Article summary",
  "status": "Draft",
  "visibility": "Public",
  "language": "en",
  "published_at": "2024-01-01T00:00:00Z",
  "thumbnail_url": "https://...",
  "tags": ["tag1", "tag2"],
  "domain": "Finance",
  "categories": ["Finance", "Business"],
  "business_stage": ["Growth", "Expansion"],
  "format": "Quick Reads",
  "author_name": "John Doe"
}
```

**Child Payload (varies by type):**

**For Articles:**
```json
{
  "type": "Article",
  "data": {
    "body_html": "<p>Content...</p>",
    "body_json": {...},
    "byline": "John Doe",
    "source": "Company Name",
    "announcement_date": null,
    "document_url": null
  }
}
```

**For Videos:**
```json
{
  "type": "Video",
  "data": {
    "video_url": "https://...",
    "platform": null,
    "duration_sec": 120,
    "transcript_url": null
  }
}
```

**For Podcasts:**
```json
{
  "type": "Podcast",
  "data": {
    "audio_url": "https://...",
    "is_video_episode": false,
    "episode_no": 1,
    "duration_sec": null,
    "transcript_url": null
  }
}
```

**For Toolkits:**
```json
{
  "type": "Tool",
  "data": {
    "document_url": "https://...",
    "file_size_mb": 2.5,
    "file_type": "pdf",
    "body_html": "<p>Description...</p>",
    "body_json": {...},
    "toc": [...],
    "requirements": [...],
    "highlights": [...],
    "version": "1.0",
    "release_date": "2024-01-01",
    "changelog_html": "<p>Changes...</p>",
    "changelog_json": {...},
    "attachments": [...],
    "categories": [...],
    "business_stage": [...],
    "format": "...",
    "tags": [...]
  }
}
```

---

### Query 5: Update Metadata After Create/Update

**Location:** `src/components/media-content-form/hooks/useMediaContentFormController.ts`

**Query:**
```sql
UPDATE cnt_contents
SET 
  metadata = :updatedMetadata,
  author_name = :authorName,
  published_at = :publishedAt,
  updated_at = NOW()
WHERE id = :contentId;
```

**Updated Metadata Structure:**
```json
{
  // Existing metadata preserved
  ...existingMetadata,
  
  // Author details
  "author_name": "John Doe",
  "author_org": "Company Name",
  "author_title": "CEO",
  "author_bio": "Biography text...",
  "author_photo_url": "https://...",
  "author_email": "john@example.com",
  "author_twitter": "@johndoe",
  "author_instagram": "@johndoe",
  
  // Insights
  "insights": ["Insight 1", "Insight 2", "Insight 3"],
  
  // Toolkit metadata (if applicable)
  "toolkit": {
    "categories": [...],
    "businessStages": [...],
    "tags": [...],
    "bodyHtml": "...",
    "bodyJson": {...},
    "toc": [...],
    "requirements": [...],
    "highlights": [...],
    "version": "1.0",
    "releaseDate": "2024-01-01",
    "changelogHtml": "...",
    "changelogJson": {...},
    "fileType": "pdf",
    "attachments": [...],
    "authors": [...],
    "format": "...",
    "documentUrl": "...",
    "fileSizeLabel": "2.5 MB"
  }
}
```

---

### Query 6: Update Existing Content

**Location:** `src/services/knowledgehub.ts` → `updateMedia()`

**Query:**
```sql
-- RPC function call
SELECT update_media_item(
  _id := :contentId,
  _base := :basePayload,
  _type := :contentType,
  _child := :childPayload,
  _facet_value_ids := NULL,
  _tag_ids := NULL,
  _collection_ids := NULL,
  _user_id := NULL
);
```

**Same payload structure as create, but with content ID**

---

## 🔍 Utility Queries

### Query 7: Check Slug Exists

**Location:** `src/services/knowledgehub.ts` → `checkSlugExists()`

**Query:**
```sql
SELECT id
FROM cnt_contents
WHERE slug = :slug
LIMIT 1;
```

**Purpose:**
- Validates slug uniqueness before creating content
- Prevents duplicate slugs

---

### Query 8: Verify Saved Content

**Location:** `src/components/media-content-form/hooks/useMediaContentFormController.ts`

**Query:**
```sql
SELECT 
  id,
  title,
  slug,
  content,
  metadata,
  author_name,
  updated_at,
  published_at,
  thumbnail_url,
  category,
  tags,
  content_url
FROM cnt_contents
WHERE id = :contentId;
```

**Purpose:**
- Verifies content was saved correctly
- Used for debugging/logging
- Runs after create/update operations

---

## 📊 Data Flow Diagram

```
User Action                Query Flow                              Database
─────────────────────────────────────────────────────────────────────────────

1. View Content List
   ↓
   useKHContent.list()
   ↓
   listMedia()
   ↓
   Query 1: SELECT * FROM v_media_all          →    v_media_all view
   ↓
   Query 2: SELECT metadata FROM cnt_contents  →    cnt_contents table
   ↓
   Merge results
   ↓
   Display in ContentManagementPage


2. Edit Content
   ↓
   Navigate to /content-form/:id
   ↓
   useMediaContentFormController
   ↓
   Query 3: SELECT * FROM cnt_contents         →    cnt_contents table
   Query 3a: SELECT * FROM v_media_all         →    v_media_all view
   Query 3b: get_content_facet_values()        →    RPC function
   Query 3c: get_content_tags()                →    RPC function
   ↓
   Parse metadata
   ↓
   Populate form fields


3. Create New Content
   ↓
   Fill form and submit
   ↓
   Query 7: Check slug exists                  →    cnt_contents table
   ↓
   Query 4: create_media_item()                →    RPC function
   ↓                                                 ↓
   Query 5: UPDATE metadata                    →    cnt_contents table
   ↓
   Query 8: Verify saved                       →    cnt_contents table
   ↓
   Success!


4. Update Existing Content
   ↓
   Modify form and submit
   ↓
   Query 6: update_media_item()                →    RPC function
   ↓
   Query 5: UPDATE metadata                    →    cnt_contents table
   ↓
   Query 8: Verify saved                       →    cnt_contents table
   ↓
   Query 3: Reload content                     →    cnt_contents table
   ↓
   Success!
```

---

## 🗂️ Database Tables & Views

### Tables Used:

1. **`cnt_contents`** - Main content table
   - Stores all content items
   - Has `metadata` JSONB column for flexible data
   - Has `author_name` column
   - Has RLS policies for access control

2. **`cnt_articles`** - Article-specific data
   - Linked to `cnt_contents` via foreign key
   - Stores `body_html`, `body_json`, `byline`, `source`

3. **`cnt_videos`** - Video-specific data
   - Stores `video_url`, `duration_sec`, `platform`

4. **`cnt_podcasts`** - Podcast-specific data
   - Stores `audio_url`, `episode_no`, `is_video_episode`

5. **`cnt_reports`** - Report-specific data
   - Stores `document_url`, `file_size_mb`, `pages`

6. **`cnt_tools`** - Toolkit-specific data
   - Stores `document_url`, `file_size_mb`, `file_type`
   - Plus toolkit-specific fields

### Views Used:

1. **`v_media_all`** - Unified view of all content
   - Joins `cnt_contents` with type-specific tables
   - Provides flattened structure for easy querying
   - Optimized for list views
   - Includes computed fields like `article_byline`

---

## 🔐 Row Level Security (RLS)

Your queries respect RLS policies:

**For Admin Users (internal):**
- Can see ALL content regardless of organization
- No organization filter applied

**For Partner Users:**
- Can only see content from their organization
- Filter: `organization_id = user_organization_id`

**For Customer Users:**
- Blocked from Content management
- Cannot access `cnt_contents` table

---

## 📈 Query Performance Tips

### Current Optimizations:

1. **View Usage:** `v_media_all` pre-joins tables for faster list queries
2. **Indexing:** Indexes on `status`, `created_at`, `organization_id`
3. **Limit:** Default limit of 100 items prevents large data transfers
4. **Selective Fields:** Only fetches needed fields in some queries

### Potential Improvements:

1. **Pagination:** Add offset-based or cursor-based pagination
2. **Caching:** Cache frequently accessed content
3. **Lazy Loading:** Load metadata only when needed
4. **Search Index:** Add full-text search index for better search performance

---

## 🧪 Testing Queries

### Test Query 1: Check if insights are saved

```sql
SELECT 
  id,
  title,
  metadata->>'author_email' as email,
  metadata->>'author_twitter' as twitter,
  metadata->>'author_instagram' as instagram,
  metadata->'insights' as insights,
  jsonb_array_length(metadata->'insights') as insights_count
FROM cnt_contents
WHERE metadata->'insights' IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

### Test Query 2: Check content by type

```sql
SELECT 
  content_type,
  COUNT(*) as count,
  COUNT(CASE WHEN status = 'Published' THEN 1 END) as published_count
FROM cnt_contents
GROUP BY content_type
ORDER BY count DESC;
```

### Test Query 3: Check metadata structure

```sql
SELECT 
  id,
  title,
  jsonb_object_keys(metadata) as metadata_keys
FROM cnt_contents
WHERE id = 'YOUR_CONTENT_ID';
```

---

## 📝 Summary

**Total Queries Used:** 8 main queries + variations

**Query Types:**
- **List Queries:** 2 (v_media_all + metadata fetch)
- **Detail Queries:** 4 (content + view + facets + tags)
- **Create/Update:** 2 (RPC functions)
- **Utility:** 2 (slug check + verification)

**Data Sources:**
- `v_media_all` view (optimized for lists)
- `cnt_contents` table (full details + metadata)
- RPC functions (create/update operations)

**Key Points:**
- Metadata is stored as JSONB in `cnt_contents.metadata`
- Insights and social links are in metadata
- Two-step fetch: view first, then metadata
- RLS policies filter by organization for non-internal users

---

## 🔗 Related Files

- `src/hooks/useKHContent.ts` - List content hook
- `src/services/knowledgehub.ts` - Query functions
- `src/components/media-content-form/hooks/useMediaContentFormController.ts` - Edit form logic
- `src/types/knowledgehub.ts` - Type definitions

---

**Last Updated:** December 2, 2024
