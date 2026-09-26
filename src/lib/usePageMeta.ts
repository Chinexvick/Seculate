import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

const SITE = 'Seculate';
const ORIGIN = 'https://seculate-black.vercel.app';
const DEFAULT_DESC =
  'Seculate connects you with people and businesses nearby. Borrow, lend and get things done easily.';

/** Sets the document title, meta description and canonical URL for the current page. */
export function usePageMeta(title?: string, description?: string) {
  const { pathname } = useLocation();
  useEffect(() => {
    document.title = title ? `${title} — ${SITE}` : `${SITE} — Borrow and lend what you have`;
    const meta = document.querySelector('meta[name="description"]');
    meta?.setAttribute('content', description ?? DEFAULT_DESC);
    // Each page is its own canonical URL, so search engines index them separately.
    document.querySelector('link[rel="canonical"]')?.setAttribute('href', `${ORIGIN}${pathname}`);
  }, [title, description, pathname]);
}
