import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import '@fontsource/inter/400.css';
import '@fontsource/inter/600.css';
import '@fontsource/inter/700.css';
import './styles.css';
import './pages.css';
import App from './App';

// Pages arrive prerendered (scripts/prerender.mjs) so search engines and link previews see real
// content. The app then renders fresh on top of that HTML in the browser.
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
);
