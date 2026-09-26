import { useEffect, useRef, type CSSProperties, type PointerEvent } from 'react';
import { motion, useInView } from 'framer-motion';
import { Art } from '../lib/Art';
import { scaleIn, stagger } from '../lib/motion';
import { SectionHead } from './SectionHead';

type Category = {
  key: string;
  desktopLabel: string;
  mobileLabel?: string;
  icon: string;
  hoodie?: boolean;
  /** Mobile label wraps onto two lines inside this width (Figma: 58px / 39px). */
  wrapWidth?: number;
  /** In the mobile Figma frame these sit partly/fully off-screen -> horizontal scroll. */
  offscreenOnMobile?: boolean;
};

const categories: Category[] = [
  { key: 'electronics', desktopLabel: 'Electronics & Appliances', mobileLabel: 'Electronics', icon: 'cat-electronics.svg' },
  { key: 'services', desktopLabel: 'Services', icon: 'cat-services.svg' },
  { key: 'sports', desktopLabel: 'Sports', icon: 'cat-sports.svg' },
  { key: 'vehicles', desktopLabel: 'Vehicles', icon: 'cat-vehicles.svg' },
  { key: 'cleaning', desktopLabel: 'Cleaning & Utility', icon: 'cat-cleaning.svg', wrapWidth: 58, offscreenOnMobile: true },
  { key: 'media', desktopLabel: 'Media & Gadgets', icon: 'cat-media.svg', wrapWidth: 39, offscreenOnMobile: true },
  { key: 'fashion', desktopLabel: 'Fashion', icon: 'hoodie.svg', hoodie: true, offscreenOnMobile: true },
  { key: 'home', desktopLabel: 'Home & Living', icon: 'cat-home.svg', offscreenOnMobile: true },
];

export function Categories() {
  const rowRef = useRef<HTMLDivElement>(null);
  const inView = useInView(rowRef, { once: true, amount: 0.6 });
  const drag = useRef({ active: false, startX: 0, startScroll: 0, moved: false });

  // On mobile, nudge the row once so people notice the off-screen cards are scrollable.
  useEffect(() => {
    const el = rowRef.current;
    if (!inView || !el) return;
    if (window.matchMedia('(min-width: 1024px)').matches) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (el.scrollWidth <= el.clientWidth) return;

    let raf = 0;
    const start = performance.now();
    const delay = 900;
    const duration = 1100;
    const distance = 64;
    const tick = (now: number) => {
      const t = now - start - delay;
      if (t > 0 && t < duration) {
        const p = t / duration;
        el.scrollLeft = Math.sin(p * Math.PI) * distance; // out and back
      } else if (t >= duration) {
        el.scrollLeft = 0;
        return;
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    const cancel = () => cancelAnimationFrame(raf);
    el.addEventListener('pointerdown', cancel, { once: true });
    el.addEventListener('touchstart', cancel, { once: true, passive: true });
    return cancel;
  }, [inView]);

  // Click-and-drag scrolling for mouse users (touch already scrolls natively).
  const onPointerDown = (e: PointerEvent<HTMLDivElement>) => {
    if (e.pointerType !== 'mouse' || !rowRef.current) return;
    drag.current = { active: true, startX: e.clientX, startScroll: rowRef.current.scrollLeft, moved: false };
  };
  const onPointerMove = (e: PointerEvent<HTMLDivElement>) => {
    const el = rowRef.current;
    if (!drag.current.active || !el) return;
    const dx = e.clientX - drag.current.startX;
    if (Math.abs(dx) > 4) {
      drag.current.moved = true;
      el.classList.add('is-dragging');
    }
    el.scrollLeft = drag.current.startScroll - dx;
  };
  const endDrag = () => {
    drag.current.active = false;
    rowRef.current?.classList.remove('is-dragging');
  };

  return (
    <section className="section section--cats wrap" id="services">
      <SectionHead eyebrow="EXPLORE" title="Browse by category" subtitle="Find what you need, when you need it." />

      <motion.div
        ref={rowRef}
        className="cats__row"
        variants={stagger(0.07)}
        initial="hidden"
        whileInView="show"
        viewport={{ once: true, amount: 0.3 }}
        role="list"
        aria-label="Categories (scroll horizontally for more)"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endDrag}
        onPointerLeave={endDrag}
        onPointerCancel={endDrag}
      >
        {categories.map((c) => (
          <motion.a
            key={c.key}
            href="#download"
            className="cat"
            role="listitem"
            variants={scaleIn}
            draggable={false}
            onClick={(e) => {
              if (drag.current.moved) {
                e.preventDefault();
                drag.current.moved = false;
              }
            }}
            style={c.wrapWidth ? ({ '--lw': `${c.wrapWidth}px` } as CSSProperties) : undefined}
          >
            <span className="cat__art">
              <Art name="cat-circle.svg" />
              <Art name={c.icon} className={`cat__icon ${c.hoodie ? 'art--hoodie' : ''}`} />
            </span>
            <span className={`cat__label ${c.wrapWidth ? 'cat__label--wrap' : ''}`}>
              {c.mobileLabel ? (
                <>
                  <span className="only-mobile">{c.mobileLabel}</span>
                  <span className="only-desktop">{c.desktopLabel}</span>
                </>
              ) : (
                c.desktopLabel
              )}
            </span>
          </motion.a>
        ))}
      </motion.div>
    </section>
  );
}
