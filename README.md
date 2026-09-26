# Seculate landing page

React + TypeScript + Vite + Framer Motion (plain CSS, no Tailwind).

    npm install
    npm run dev      # http://localhost:5173
    npm run build    # output in dist/

Figma source: file `0TwDI46C3KSgdqb3uxdsiX`, nodes 5-393 (desktop), 5-633 (mobile),
17-74 / 17-70 / 17-60 / 17-64 (the four mobile category cards that sit off-screen).

## Layout
- Mobile layout matches the 390px frame; desktop layout (>= 1024px) matches the 1440px frame.
- Mobile categories row scrolls horizontally (scroll-snap). Off-screen in Figma: Cleaning & Utility,
  Media & Gadgets, Fashion, Home & Living. Mouse drag-to-scroll is supported.

## Scroll animation (src/lib/motion.ts, src/components/*)
Scroll progress bar, nav slide-in and scrolled state, word-by-word hero headline, hero image parallax,
staggered reveals for categories / steps / pricing / community / footer, spinning sparkle, scroll-scrubbed CTA.
`MotionConfig reducedMotion="user"` respects the OS reduced-motion setting.
