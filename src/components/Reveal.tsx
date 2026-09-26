import { motion, type Variants } from 'framer-motion';
import type { CSSProperties, ReactNode } from 'react';
import { fadeUp, viewport } from '../lib/motion';

type RevealProps = {
  children: ReactNode;
  className?: string;
  style?: CSSProperties;
  variants?: Variants;
  delay?: number;
  id?: string;
};

/** Fades/slides its children in the first time they scroll into view. */
export function Reveal({ children, className, style, variants = fadeUp, delay = 0, id }: RevealProps) {
  return (
    <motion.div
      id={id}
      className={className}
      style={style}
      variants={variants}
      initial="hidden"
      whileInView="show"
      viewport={viewport}
      transition={delay ? { delay } : undefined}
    >
      {children}
    </motion.div>
  );
}
