import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';
import App from './App';

export { routes, metaFor, jsonLdFor, canonicalFor, fullTitle, DEFAULT_DESCRIPTION, DEFAULT_IMAGE, SITE_URL } from './seo';
export { posts } from './content/blog';

/** Renders one URL to static HTML (used only by the build-time prerender). */
export function render(url: string) {
  return renderToString(
    <StaticRouter location={url}>
      <App />
    </StaticRouter>,
  );
}
