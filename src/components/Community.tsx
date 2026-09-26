import type { CSSProperties } from 'react';
import { motion } from 'framer-motion';
import { fadeUp, pop, stagger, viewport } from '../lib/motion';
import { SectionHead } from './SectionHead';

type Quote = {
  name: string;
  role: string;
  text: string;
  avatar: 'tunde' | 'fatima' | 'chinedu';
  /** Desktop offsets from the Figma frame: avatar x/y, quote y, stars y. */
  d: { ax: number; ay: number; qy: number; sy: number };
  /** Mobile avatar offsets from the Figma frame. */
  m: { ax: number; ay: number };
};

const quotes: Quote[] = [
  {
    name: 'Tunde A.',
    role: 'Student',
    text: '“Seculate helped me get a laptop for my project without spending a fortune.”',
    avatar: 'tunde',
    d: { ax: 35, ay: 15, qy: 80, sy: 135 },
    m: { ax: 17, ay: 16 },
  },
  {
    name: 'Fatima B.',
    role: 'Small Business Owner',
    text: '“I’ve rented a few items for my business and the process is always smooth.”',
    avatar: 'fatima',
    d: { ax: 26, ay: 18, qy: 83, sy: 138 },
    m: { ax: 21, ay: 18 },
  },
  {
    name: 'Chinedu K.',
    role: 'Freelancer',
    text: '“Great platform! I listed a camera I don’t use often and got it rented quickly.”',
    avatar: 'chinedu',
    d: { ax: 10, ay: 18, qy: 83, sy: 138 },
    m: { ax: 21, ay: 18 },
  },
];

export function Community() {
  return (
    <section className="section section--community wrap wrap--narrow">
      <SectionHead eyebrow="COMMUNITY" title="What our community says" />

      <motion.div
        className="quotes"
        variants={stagger(0.13)}
        initial="hidden"
        whileInView="show"
        viewport={viewport}
      >
        {quotes.map((q) => (
          <motion.figure
            key={q.name}
            className="quote"
            variants={fadeUp}
            style={
              {
                margin: 0,
                '--ax': `${q.d.ax}px`,
                '--ay': `${q.d.ay}px`,
                '--qy': `${q.d.qy}px`,
                '--sy': `${q.d.sy}px`,
                '--m-ax': `${q.m.ax}px`,
                '--m-ay': `${q.m.ay}px`,
              } as CSSProperties
            }
          >
            <picture>
              <source media="(min-width: 1024px)" srcSet={`/assets/desktop/avatar-${q.avatar}.png`} />
              <motion.img
                className="quote__avatar"
                src={`/assets/mobile/avatar-${q.avatar}.png`}
                alt=""
                width={38}
                height={38}
                variants={pop}
              />
            </picture>
            <figcaption>
              <span className="quote__name">{q.name}</span>
              <span className="quote__role">{q.role}</span>
            </figcaption>
            <blockquote className="quote__text" style={{ margin: 0 }}>
              {q.text}
            </blockquote>
            <span className="quote__stars" aria-label="5 out of 5 stars">
              ★★★★★
            </span>
          </motion.figure>
        ))}
      </motion.div>
    </section>
  );
}
