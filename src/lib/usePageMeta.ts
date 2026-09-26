import { useEffect } from 'react';

const SITE = 'Seculate';
const DEFAULT_DESC =
  'Seculate connects you with people and businesses nearby. Borrow, lend and get things done easily.';

/** Sets the document title and meta description for the current page. */
export function usePageMeta(title?: string, description?: string) {
  useEffect(() => {
    document.title = title ? `${title} — ${SITE}` : `${SITE} — Borrow and lend what you have`;
    const meta = document.querySelector('meta[name="description"]');
    meta?.setAttribute('content', description ?? DEFAULT_DESC);
  }, [title, description]);
}
