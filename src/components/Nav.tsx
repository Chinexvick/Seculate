import { useState } from 'react';
import { AnimatePresence, motion, useMotionValueEvent, useScroll } from 'framer-motion';
import { ease } from '../lib/motion';
import { Logo } from './Logo';

const links = [
  { label: 'Services', href: '#services' },
  { label: 'How it works', href: '#how' },
  { label: 'Pricing', href: '#pricing' },
];

export function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, 'change', (y) => setScrolled(y > 8));

  return (
    <motion.header
      className={`nav ${scrolled ? 'nav--scrolled' : ''}`}
      initial={{ y: -72, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.7, ease }}
    >
      <div className="nav__inner">
        <Logo />

        <nav className="nav__tabs" aria-label="Primary">
          {links.map((l) => (
            <a key={l.href} href={l.href}>
              {l.label}
            </a>
          ))}
        </nav>

        <div className="nav__cta">
          <a href="#download" className="nav__signin">
            Sign in
          </a>
          <motion.a href="#download" className="btn btn--green" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.97 }}>
            Get started
          </motion.a>
        </div>

        <button
          type="button"
          className="nav__burger"
          aria-label={open ? 'Close menu' : 'Open menu'}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <motion.span animate={{ rotate: open ? 90 : 0 }} transition={{ duration: 0.25 }}>
            {open ? '✕' : '☰'}
          </motion.span>
        </button>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            className="menu"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease }}
          >
            <div className="menu__list">
              {links.map((l) => (
                <a key={l.href} href={l.href} className="menu__link" onClick={() => setOpen(false)}>
                  {l.label}
                </a>
              ))}
              <a href="#download" className="btn btn--green menu__cta" onClick={() => setOpen(false)}>
                Get started
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}
