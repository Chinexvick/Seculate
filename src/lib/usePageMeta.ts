import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { DEFAULT_DESCRIPTION, DEFAULT_IMAGE, canonicalFor, fullTitle, metaFor, type PageMeta } from '../seo';

const setAttr = (selector: string, attr: string, value: string) =>
  document.querySelector(selector)?.setAttribute(attr, value);

/**
 * Keeps <head> in sync while navigating between pages in the browser.
 * The same values are written into each page's static HTML at build time (scripts/prerender.mjs).
 */
export function usePageMeta(override?: PageMeta) {
  const { pathname } = useLocation();
  const meta = override ?? metaFor(pathname);
  useEffect(() => {
    const title = fullTitle(meta.title);
    const description = meta.description ?? DEFAULT_DESCRIPTION;
    const url = canonicalFor(pathname);
    const image = meta.image ?? DEFAULT_IMAGE;
    document.title = title;
    setAttr('meta[name="description"]', 'content', description);
    setAttr('link[rel="canonical"]', 'href', url);
    setAttr('meta[property="og:title"]', 'content', title);
    setAttr('meta[property="og:description"]', 'content', description);
    setAttr('meta[property="og:url"]', 'content', url);
    setAttr('meta[property="og:image"]', 'content', image);
    setAttr('meta[property="og:type"]', 'content', meta.type ?? 'website');
    setAttr('meta[name="twitter:title"]', 'content', title);
    setAttr('meta[name="twitter:description"]', 'content', description);
    setAttr('meta[name="twitter:image"]', 'content', image);
    setAttr('meta[name="robots"]', 'content', meta.noindex ? 'noindex, follow' : 'index, follow');
  }, [pathname, meta.title, meta.description, meta.image, meta.type, meta.noindex]);
}
