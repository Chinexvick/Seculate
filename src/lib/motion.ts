import type { Variants } from 'framer-motion';

/** Shared easing — a soft "expo out" that feels natural on scroll reveals. */
export const ease = [0.22, 1, 0.36, 1] as const;

/** Default viewport config: animate once, slightly before the element is fully in view. */
export const viewport = { once: true, amount: 0.25 } as const;

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 32 },
  show: { opacity: 1, y: 0, transition: { duration: 0.7, ease } },
};

export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { duration: 0.6, ease } },
};

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.88, y: 24 },
  show: { opacity: 1, scale: 1, y: 0, transition: { duration: 0.6, ease } },
};

export const pop: Variants = {
  hidden: { opacity: 0, scale: 0.4 },
  show: { opacity: 1, scale: 1, transition: { type: 'spring', stiffness: 380, damping: 18 } },
};

/** Parent variant that staggers its children. */
export const stagger = (staggerChildren = 0.09, delayChildren = 0): Variants => ({
  hidden: {},
  show: { transition: { staggerChildren, delayChildren } },
});

/** Word-by-word headline reveal. */
export const wordReveal: Variants = {
  hidden: { opacity: 0, y: '0.6em', rotateX: -35 },
  show: { opacity: 1, y: 0, rotateX: 0, transition: { duration: 0.7, ease } },
};
