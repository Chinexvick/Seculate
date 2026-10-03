import { posts, findPost } from './content/blog';
import { helpTopics } from './content/help';

/**
 * Single source of truth for page metadata. Used by the client (usePageMeta) and by the
 * build-time prerender (scripts/prerender.mjs) so every page ships real HTML with the right
 * <title>, description, canonical URL, social preview and structured data.
 */
export const SITE_URL = 'https://www.seculate.ng';
export const SITE_NAME = 'Seculate';
export const DEFAULT_TITLE = 'Seculate — Borrow and lend what you have';
export const DEFAULT_DESCRIPTION =
  'Seculate connects you with people and businesses nearby. Borrow, lend and rent everyday items, find trusted local services, and pay safely with escrow.';
export const DEFAULT_IMAGE = `${SITE_URL}/og-image.png`;

export type PageMeta = {
  title?: string;
  description?: string;
  image?: string;
  type?: 'website' | 'article';
  noindex?: boolean;
};

const pages: Record<string, PageMeta> = {
  '/': {},
  '/about': {
    title: 'About us',
    description: 'Seculate helps people borrow, lend and rent what they already have, and find trusted local services nearby.',
  },
  '/contact': {
    title: 'Contact us',
    description: 'Get in touch with the Seculate team for support, partnerships, press or feedback.',
  },
  '/careers': {
    title: 'Careers',
    description: 'Help build the trusted way to borrow, lend and get things done. Work with Seculate.',
  },
  '/partners': {
    title: 'Partner with us',
    description: 'Grow your business with Seculate: reach verified customers nearby who need what you offer.',
  },
  '/help': {
    title: 'Help center',
    description: 'Answers to common questions about borrowing, lending, plans, escrow, safety and your Seculate account.',
  },
  '/safety': {
    title: 'Safety',
    description: 'How Seculate keeps borrowing, lending and local services safe: verified users, ratings, in-app chat and secure escrow.',
  },
  '/community': {
    title: 'Community',
    description: 'The Seculate community: guidelines, member stories and how to get involved.',
  },
  '/blog': {
    title: 'Blog',
    description: 'Guides and stories on saving money, earning from what you own and staying safe while you share.',
  },
  '/privacy': { title: 'Privacy Policy', description: 'How Seculate collects, uses and protects your personal data.' },
  '/terms': { title: 'Terms of Service', description: 'The terms that govern your use of the Seculate app and website.' },
};

export const NOT_FOUND_META: PageMeta = { title: 'Page not found', noindex: true };

const pexelsImage = (id: number) =>
  `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=1200&h=630&fit=crop`;

/** Every indexable route, used for prerendering and the sitemap. */
export const routes: string[] = [...Object.keys(pages), ...posts.map((p) => `/blog/${p.slug}`)];

export function metaFor(pathname: string): PageMeta {
  const path = normalise(pathname);
  if (pages[path]) return pages[path];
  const post = path.startsWith('/blog/') ? findPost(path.slice(6)) : undefined;
  if (post) {
    return {
      title: post.title,
      description: post.excerpt,
      image: post.image.pexels ? pexelsImage(post.image.pexels) : undefined,
      type: 'article',
    };
  }
  return NOT_FOUND_META;
}

export const fullTitle = (title?: string) => (title ? `${title} — ${SITE_NAME}` : DEFAULT_TITLE);
export const canonicalFor = (pathname: string) => `${SITE_URL}${normalise(pathname) === '/' ? '/' : normalise(pathname)}`;

function normalise(pathname: string) {
  const p = pathname.split(/[?#]/)[0].replace(/\/+$/, '');
  return p === '' ? '/' : p;
}

/** Page-specific structured data (the Organization block lives in index.html for every page). */
export function jsonLdFor(pathname: string): object[] {
  const path = normalise(pathname);
  const crumbs = (items: [string, string][]) => ({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map(([name, url], i) => ({ '@type': 'ListItem', position: i + 1, name, item: `${SITE_URL}${url}` })),
  });

  if (path === '/') {
    return [{ '@context': 'https://schema.org', '@type': 'WebSite', name: SITE_NAME, url: `${SITE_URL}/` }];
  }
  if (path === '/help') {
    return [
      {
        '@context': 'https://schema.org',
        '@type': 'FAQPage',
        mainEntity: helpTopics.flatMap((t) =>
          t.faqs.map((f) => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })),
        ),
      },
      crumbs([['Home', '/'], ['Help center', '/help']]),
    ];
  }
  const post = path.startsWith('/blog/') ? findPost(path.slice(6)) : undefined;
  if (post) {
    return [
      {
        '@context': 'https://schema.org',
        '@type': 'BlogPosting',
        headline: post.title,
        description: post.excerpt,
        image: metaFor(path).image,
        datePublished: post.date,
        dateModified: post.date,
        author: { '@type': 'Organization', name: post.author },
        publisher: {
          '@type': 'Organization',
          name: SITE_NAME,
          logo: { '@type': 'ImageObject', url: `${SITE_URL}/icon-512.png` },
        },
        mainEntityOfPage: `${SITE_URL}${path}`,
      },
      crumbs([['Home', '/'], ['Blog', '/blog'], [post.title, path]]),
    ];
  }
  const meta = pages[path];
  return meta?.title ? [crumbs([['Home', '/'], [meta.title, path]])] : [];
}
