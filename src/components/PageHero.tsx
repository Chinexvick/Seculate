import type { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { fadeUp, stagger } from '../lib/motion';
import { Photo, type PhotoSource } from './Photo';

type Props = {
  eyebrow: string;
  title: ReactNode;
  lead?: ReactNode;
  photo?: PhotoSource;
  children?: ReactNode;
};

/** Shared header for the inner pages: eyebrow, big title, lead and an optional graded photo. */
export function PageHero({ eyebrow, title, lead, photo, children }: Props) {
  return (
    <section className={`phero ${photo ? 'phero--photo' : ''}`}>
      <div className="phero__inner">
        <motion.div className="phero__copy" variants={stagger(0.08)} initial="hidden" animate="show">
          <motion.p className="eyebrow" variants={fadeUp}>
            {eyebrow}
          </motion.p>
          <motion.h1 className="phero__title" variants={fadeUp}>
            {title}
          </motion.h1>
          {lead && (
            <motion.p className="phero__lead" variants={fadeUp}>
              {lead}
            </motion.p>
          )}
          {children && <motion.div variants={fadeUp}>{children}</motion.div>}
        </motion.div>
        {photo && (
          <motion.div
            className="phero__media"
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          >
            <Photo {...photo} sizes="(min-width: 1024px) 560px, 100vw" priority />
          </motion.div>
        )}
      </div>
    </section>
  );
}
