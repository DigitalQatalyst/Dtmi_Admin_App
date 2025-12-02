# Frontend Content Display Setup Guide
## Separate Vite + TypeScript + React Project

This guide will help you set up a separate frontend project to display content articles from your Supabase database.

---

## 📋 Project Overview

**Goal:** Create a public-facing content display application that:
1. Fetches content articles from Supabase
2. Displays them as cards in a grid/list view
3. Shows full article details when a card is clicked
4. Includes insights and author social links

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Frontend App (Vite)                    │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Articles List Page                                 │ │
│  │  - Grid of article cards                           │ │
│  │  - Filter by category, type, tags                  │ │
│  │  - Search functionality                            │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Article Detail Page                               │ │
│  │  - Full article content                            │ │
│  │  - Author info with social links                   │ │
│  │  - Key insights section                            │ │
│  │  - Related articles                                │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            ↓
                    Supabase Client
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Supabase Database                     │
│  - cnt_contents table (with metadata JSONB)             │
│  - v_media_all view (for optimized queries)             │
│  - RLS policies (public read access)                    │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Setup Steps

### Step 1: Project Initialization

```bash
# Create new Vite project
npm create vite@latest content-display-app -- --template react-ts

cd content-display-app

# Install dependencies
npm install

# Install required packages
npm install @supabase/supabase-js
npm install react-router-dom
npm install lucide-react  # For icons
npm install date-fns      # For date formatting
npm install dompurify     # For sanitizing HTML content
npm install @types/dompurify --save-dev
```

### Step 2: Environment Configuration

Create `.env` file in the root:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here

# Optional: API URL if you're using a backend API
VITE_API_BASE_URL=https://your-api.com
```

**Important:** Use the **anon key** (not service role key) for public access.

---

## 📁 Project Structure

```
src/
├── components/
│   ├── ArticleCard.tsx           # Card component for article preview
│   ├── ArticleDetail.tsx         # Full article view
│   ├── ArticleList.tsx           # Grid/list of articles
│   ├── FilterBar.tsx             # Filters and search
│   ├── InsightsSection.tsx       # Display key insights
│   ├── AuthorInfo.tsx            # Author details with social links
│   └── RelatedArticles.tsx       # Related content suggestions
├── hooks/
│   ├── useArticles.ts            # Fetch articles from Supabase
│   ├── useArticleDetail.ts      # Fetch single article
│   └── useRelatedArticles.ts    # Fetch related content
├── lib/
│   ├── supabase.ts               # Supabase client setup
│   └── types.ts                  # TypeScript types
├── pages/
│   ├── ArticlesPage.tsx          # List view page
│   └── ArticleDetailPage.tsx     # Detail view page
├── utils/
│   ├── formatters.ts             # Date, text formatting
│   └── sanitize.ts               # HTML sanitization
├── App.tsx
└── main.tsx
```

---

## 🔧 Implementation Guide

### Step 3: Supabase Client Setup

**File:** `src/lib/supabase.ts`

```typescript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

---

### Step 4: TypeScript Types

**File:** `src/lib/types.ts`

```typescript
export interface Article {
  id: string;
  title: string;
  slug: string;
  summary: string;
  content: string;
  type: 'Article' | 'News' | 'Guide' | 'Video' | 'Podcast' | 'Report' | 'Tool';
  status: 'Published' | 'Draft' | 'Archived';
  author_name: string;
  thumbnail_url: string;
  published_at: string;
  created_at: string;
  updated_at: string;
  tags: string[];
  categories: string[];
  domain: string;
  metadata: ArticleMetadata;
}

export interface ArticleMetadata {
  // Author details
  author_name?: string;
  author_org?: string;
  author_title?: string;
  author_bio?: string;
  author_photo_url?: string;
  author_email?: string;
  author_twitter?: string;
  author_instagram?: string;
  
  // Content insights
  insights?: string[];
  
  // Toolkit specific (if type is Tool)
  toolkit?: {
    bodyHtml?: string;
    toc?: any[];
    requirements?: any[];
    highlights?: any[];
    version?: string;
    releaseDate?: string;
    fileType?: string;
    attachments?: any[];
    authors?: any[];
  };
}

export interface ArticleFilters {
  search?: string;
  type?: string;
  category?: string;
  tags?: string[];
}
```

---

### Step 5: Data Fetching Hook

**File:** `src/hooks/useArticles.ts`

```typescript
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Article, ArticleFilters } from '../lib/types';

export function useArticles(filters?: ArticleFilters) {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchArticles();
  }, [filters]);

  const fetchArticles = async () => {
    try {
      setLoading(true);
      
      // Build query
      let query = supabase
        .from('cnt_contents')
        .select('*')
        .eq('status', 'Published')  // Only show published content
        .order('published_at', { ascending: false });

      // Apply filters
      if (filters?.type && filters.type !== 'All') {
        query = query.eq('content_type', filters.type);
      }

      if (filters?.category && filters.category !== 'All') {
        query = query.eq('domain', filters.category);
      }

      if (filters?.search) {
        query = query.or(`title.ilike.%${filters.search}%,summary.ilike.%${filters.search}%`);
      }

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      // Parse metadata (it might be a string)
      const parsedArticles = (data || []).map(article => ({
        ...article,
        metadata: typeof article.metadata === 'string' 
          ? JSON.parse(article.metadata) 
          : article.metadata || {}
      }));

      setArticles(parsedArticles);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch articles'));
    } finally {
      setLoading(false);
    }
  };

  return { articles, loading, error, refetch: fetchArticles };
}
```

---

### Step 6: Single Article Hook

**File:** `src/hooks/useArticleDetail.ts`

```typescript
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { Article } from '../lib/types';

export function useArticleDetail(id: string) {
  const [article, setArticle] = useState<Article | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (id) {
      fetchArticle();
    }
  }, [id]);

  const fetchArticle = async () => {
    try {
      setLoading(true);

      const { data, error: fetchError } = await supabase
        .from('cnt_contents')
        .select('*')
        .eq('id', id)
        .eq('status', 'Published')  // Only show published content
        .single();

      if (fetchError) throw fetchError;

      // Parse metadata
      const parsedArticle = {
        ...data,
        metadata: typeof data.metadata === 'string' 
          ? JSON.parse(data.metadata) 
          : data.metadata || {}
      };

      setArticle(parsedArticle);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch article'));
    } finally {
      setLoading(false);
    }
  };

  return { article, loading, error, refetch: fetchArticle };
}
```

---

### Step 7: Router Setup

**File:** `src/App.tsx`

```typescript
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import ArticlesPage from './pages/ArticlesPage';
import ArticleDetailPage from './pages/ArticleDetailPage';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArticlesPage />} />
        <Route path="/articles" element={<ArticlesPage />} />
        <Route path="/articles/:id" element={<ArticleDetailPage />} />
        <Route path="/articles/slug/:slug" element={<ArticleDetailPage />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

---

### Step 8: Article Card Component

**File:** `src/components/ArticleCard.tsx`

**Key Features:**
- Display thumbnail image
- Show title, summary, author
- Display tags/categories
- Show published date
- Click to navigate to detail page

**Props:**
```typescript
interface ArticleCardProps {
  article: Article;
  onClick: () => void;
}
```

**What to display:**
- `article.thumbnail_url` - Featured image
- `article.title` - Article title
- `article.summary` - Short description
- `article.author_name` or `article.metadata.author_name` - Author
- `article.published_at` - Publication date (format with date-fns)
- `article.tags` - Tags as badges
- `article.type` - Content type icon

---

### Step 9: Article Detail Component

**File:** `src/components/ArticleDetail.tsx`

**Key Sections:**

1. **Header Section:**
   - Title
   - Author info (name, photo, organization)
   - Published date
   - Tags/categories

2. **Insights Section** (if available):
   ```typescript
   {article.metadata.insights && article.metadata.insights.length > 0 && (
     <InsightsSection insights={article.metadata.insights} />
   )}
   ```

3. **Content Section:**
   - Sanitized HTML content
   - Use DOMPurify to sanitize `article.content`

4. **Author Details Section:**
   - Full author bio
   - Social media links (email, Twitter, Instagram)
   ```typescript
   {article.metadata.author_email && (
     <a href={`mailto:${article.metadata.author_email}`}>Email</a>
   )}
   {article.metadata.author_twitter && (
     <a href={`https://twitter.com/${article.metadata.author_twitter.replace('@', '')}`}>
       Twitter
     </a>
   )}
   {article.metadata.author_instagram && (
     <a href={`https://instagram.com/${article.metadata.author_instagram.replace('@', '')}`}>
       Instagram
     </a>
   )}
   ```

5. **Related Articles Section:**
   - Query articles with same category/tags
   - Display 3-4 related article cards

---

### Step 10: Insights Component

**File:** `src/components/InsightsSection.tsx`

**Design:**
```typescript
interface InsightsSectionProps {
  insights: string[];
}

// Display as:
// - Numbered list with styled badges
// - Light blue background section
// - Icon (lightbulb) for visual appeal
// - Title: "Key Insights"
```

**Example Structure:**
```
┌─────────────────────────────────────────┐
│  💡 Key Insights                        │
│                                         │
│  1️⃣ First insight text here            │
│  2️⃣ Second insight text here           │
│  3️⃣ Third insight text here            │
└─────────────────────────────────────────┘
```

---

### Step 11: Author Info Component

**File:** `src/components/AuthorInfo.tsx`

**Props:**
```typescript
interface AuthorInfoProps {
  name: string;
  organization?: string;
  title?: string;
  bio?: string;
  photoUrl?: string;
  email?: string;
  twitter?: string;
  instagram?: string;
}
```

**Layout:**
- Author photo (circular)
- Name and title
- Organization
- Bio paragraph
- Social media icons with links

---

### Step 12: HTML Content Sanitization

**File:** `src/utils/sanitize.ts`

```typescript
import DOMPurify from 'dompurify';

export function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: [
      'p', 'br', 'strong', 'em', 'u', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li', 'a', 'img', 'blockquote', 'code', 'pre'
    ],
    ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'class']
  });
}
```

**Usage in component:**
```typescript
<div 
  dangerouslySetInnerHTML={{ 
    __html: sanitizeHtml(article.content) 
  }} 
/>
```

---

## 🔒 Supabase Security Setup

### Step 13: Row Level Security (RLS) Policies

Run this SQL in Supabase SQL Editor:

```sql
-- Enable RLS on cnt_contents
ALTER TABLE cnt_contents ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access to published content
CREATE POLICY "Public can view published content"
ON cnt_contents
FOR SELECT
USING (status = 'Published');

-- Optional: If you want to allow access via slug
CREATE INDEX IF NOT EXISTS idx_cnt_contents_slug 
ON cnt_contents(slug) 
WHERE slug IS NOT NULL;

-- Optional: Index for better performance
CREATE INDEX IF NOT EXISTS idx_cnt_contents_published 
ON cnt_contents(status, published_at DESC) 
WHERE status = 'Published';
```

---

## 🎨 UI/UX Recommendations

### Articles List Page:
- **Grid Layout:** 3 columns on desktop, 2 on tablet, 1 on mobile
- **Card Design:** Image on top, content below
- **Filters:** Sticky filter bar at top
- **Search:** Debounced search input (300ms delay)
- **Pagination:** Load more button or infinite scroll
- **Loading State:** Skeleton cards while loading
- **Empty State:** Friendly message when no articles found

### Article Detail Page:
- **Max Width:** 800px for readability
- **Typography:** Larger font for content (18px)
- **Line Height:** 1.7 for comfortable reading
- **Images:** Full width within content
- **Back Button:** Navigate back to list
- **Share Buttons:** Social media sharing
- **Reading Time:** Calculate and display estimated reading time

---

## 📊 Data Flow Diagram

```
User Action                 Component                  Hook                    Supabase
─────────────────────────────────────────────────────────────────────────────────────

1. Visit /articles    →    ArticlesPage         →    useArticles()      →    Query cnt_contents
                                                                               WHERE status = 'Published'
                                                                               ORDER BY published_at DESC
                            ↓
                       Display ArticleCard[]
                            ↓
2. Click card         →    Navigate to                                   
                           /articles/:id
                            ↓
3. View detail        →    ArticleDetailPage    →    useArticleDetail() →    Query cnt_contents
                                                                               WHERE id = :id
                                                                               AND status = 'Published'
                            ↓
                       Parse metadata
                            ↓
                       Display:
                       - ArticleDetail
                       - InsightsSection (if insights exist)
                       - AuthorInfo (with social links)
                       - RelatedArticles
```

---

## 🧪 Testing Checklist

- [ ] Articles load correctly from Supabase
- [ ] Filters work (type, category, search)
- [ ] Click on card navigates to detail page
- [ ] Article content displays properly (HTML sanitized)
- [ ] Insights section appears when data exists
- [ ] Author social links work correctly
- [ ] Images load properly
- [ ] Mobile responsive design works
- [ ] Loading states display correctly
- [ ] Error states handle gracefully
- [ ] Back navigation works
- [ ] Related articles display

---

## 🚀 Deployment

### Build for Production:

```bash
npm run build
```

### Deploy Options:

1. **Vercel:**
   ```bash
   npm install -g vercel
   vercel
   ```

2. **Netlify:**
   ```bash
   npm install -g netlify-cli
   netlify deploy --prod
   ```

3. **GitHub Pages:**
   - Set `base: '/repo-name/'` in `vite.config.ts`
   - Use GitHub Actions for deployment

---

## 📝 Environment Variables for Production

Make sure to set these in your deployment platform:

```
VITE_SUPABASE_URL=your-production-supabase-url
VITE_SUPABASE_ANON_KEY=your-production-anon-key
```

---

## 🔍 SEO Optimization (Optional)

### Add Meta Tags:

```typescript
// In ArticleDetailPage.tsx
useEffect(() => {
  if (article) {
    document.title = `${article.title} | Your Site Name`;
    
    // Update meta description
    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      metaDescription.setAttribute('content', article.summary);
    }
  }
}, [article]);
```

### Add Open Graph Tags:

```html
<!-- In index.html -->
<meta property="og:title" content="Article Title" />
<meta property="og:description" content="Article Summary" />
<meta property="og:image" content="Article Thumbnail" />
<meta property="og:type" content="article" />
```

---

## 📚 Additional Features to Consider

1. **Search Functionality:**
   - Full-text search across title, summary, content
   - Search suggestions/autocomplete

2. **Filtering:**
   - By content type (Article, Video, Podcast, etc.)
   - By category/domain
   - By tags
   - By date range

3. **Sorting:**
   - Most recent
   - Most popular (if you track views)
   - Alphabetical

4. **Bookmarking:**
   - Save articles to read later (localStorage)

5. **Reading Progress:**
   - Show reading progress bar
   - Save scroll position

6. **Comments:**
   - Add comment system (if needed)

7. **Analytics:**
   - Track page views
   - Track reading time
   - Track popular articles

---

## 🐛 Common Issues & Solutions

### Issue: CORS Errors
**Solution:** Ensure Supabase URL is correct and RLS policies allow public access

### Issue: Metadata is null
**Solution:** Check if content has metadata in database, parse as JSON if string

### Issue: Images not loading
**Solution:** Verify image URLs are absolute, check CORS headers

### Issue: HTML content not rendering
**Solution:** Use `dangerouslySetInnerHTML` with DOMPurify sanitization

### Issue: Slow loading
**Solution:** Add indexes on `status` and `published_at` columns, implement pagination

---

## 📞 Support & Resources

- **Supabase Docs:** https://supabase.com/docs
- **React Router:** https://reactrouter.com/
- **Vite Docs:** https://vitejs.dev/
- **DOMPurify:** https://github.com/cure53/DOMPurify

---

## ✅ Quick Start Checklist

1. [ ] Create new Vite project
2. [ ] Install dependencies (Supabase, React Router, etc.)
3. [ ] Set up environment variables
4. [ ] Create Supabase client
5. [ ] Define TypeScript types
6. [ ] Create data fetching hooks
7. [ ] Set up routing
8. [ ] Build ArticleCard component
9. [ ] Build ArticleDetail component
10. [ ] Build InsightsSection component
11. [ ] Build AuthorInfo component
12. [ ] Set up RLS policies in Supabase
13. [ ] Test with sample data
14. [ ] Deploy to production

---

**Good luck with your frontend project! 🚀**
