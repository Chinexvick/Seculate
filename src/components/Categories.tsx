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

/** Auto-scroll speed of the mobile category row, in pixels per second. */
const SPEED = 28;

export function Categories() {
  const rowRef = useRef<HTMLDivElement>(null);
  const inView = useInView(rowRef, { once: true, amount: 0.6 });
  const drag = useRef({ active: false, startX: 0, startScroll: 0, moved: false });

  // On mobile the row scrolls itself in an endless loop. The cards are rendered twice, so
  // when the first set has scrolled fully out of view we jump back by exactly one set,
  // which looks seamless. Touching, dragging or hovering pauses it; it resumes shortly after.
  useEffect(() => {
    const el = rowRef.current;
    if (!inView || !el) return;
    const mobile = window.matchMedia('(max-width: 1023.98px)');
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');

    let raf = 0;
    let last = 0;
    let pos = el.scrollLeft;
    let paused = false;
    let resumeTimer = 0;

    const loopWidth = () => {
      const first = el.children[0] as HTMLElement | undefined;
      const clone = el.children[categories.length] as HTMLElement | undefined;
      return first && clone ? clone.offsetLeft - first.offsetLeft : 0;
    };

    const tick = (now: number) => {
      const dt = last ? Math.min(now - last, 64) : 0;
      last = now;
      if (!paused && mobile.matches && !reduced.matches) {
        const w = loopWidth();
        pos += (SPEED * dt) / 1000;
        if (w && pos >= w) pos -= w;
        el.scrollLeft = pos;
      }
      raf = requestAnimationFrame(tick);
    };

    const pause = () => {
      paused = true;
      window.clearTimeout(resumeTimer);
    };
    const resume = () => {
      window.clearTimeout(resumeTimer);
      resumeTimer = window.setTimeout(() => {
        const w = loopWidth();
        pos = el.scrollLeft;
        if (w && pos >= w) pos %= w;
        paused = false;
      }, 1800);
    };

    const opts = { passive: true } as const;
    el.addEventListener('touchstart', pause, opts);
    el.addEventListener('touchend', resume, opts);
    el.addEventListener('touchcancel', resume, opts);
    el.addEventListener('pointerdown', pause, opts);
    el.addEventListener('pointerup', resume, opts);
    el.addEventListener('mouseenter', pause, opts);
    el.addEventListener('mouseleave', resume, opts);
    el.addEventListener('focusin', pause);
    el.addEventListener('focusout', resume);
    raf = requestAnimationFrame(tick);

    return () => {
      cancelAnimationFrame(raf);
      window.clearTimeout(resumeTimer);
      el.removeEventListener('touchstart', pause);
      el.removeEventListener('touchend', resume);
      el.removeEventListener('touchcancel', resume);
      el.removeEventListener('pointerdown', pause);
      el.removeEventListener('pointerup', resume);
      el.removeEventListener('mouseenter', pause);
      el.removeEventListener('mouseleave', resume);
      el.removeEventListener('focusin', pause);
      el.removeEventListener('focusout', resume);
    };
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
        aria-label="Categories"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endDrag}
        onPointerLeave={endDrag}
        onPointerCancel={endDrag}
      >
        {[...categories, ...categories].map((c, i) => {
          const clone = i >= categories.length;
          return (
          <motion.a
            key={clone ? `${c.key}-clone` : c.key}
            href="#download"
            className={`cat ${clone ? 'cat--clone' : ''}`}
            role={clone ? undefined : 'listitem'}
            aria-hidden={clone || undefined}
            tabIndex={clone ? -1 : undefined}
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
          );
        })}
      </motion.div>
    </section>
  );
}
