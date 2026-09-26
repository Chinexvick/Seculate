import type { CSSProperties } from 'react';
import { motion } from 'framer-motion';
import { Art } from '../lib/Art';
import { fadeUp, pop, stagger, viewport } from '../lib/motion';
import { SectionHead } from './SectionHead';

type Step = {
  n: number;
  title: string;
  desc: string;
  /** Desktop offsets taken from the Figma frame (circle x/y, title x/y, gap title->desc, desc width). */
  d: { cx: number; cy: number; tx: number; ty: number; gap: number; dw: number };
};

const steps: Step[] = [
  {
    n: 1,
    title: 'Find what you need',
    desc: 'Search for items, services or browse nearby listings.',
    d: { cx: 27, cy: 31, tx: 68, ty: 52, gap: 6, dw: 175 },
  },
  {
    n: 2,
    title: 'Connect & confirm',
    desc: 'Chat with the provider, check details and confirm your request.',
    d: { cx: 18, cy: 18, tx: 70, ty: 39, gap: 7, dw: 238 },
  },
  {
    n: 3,
    title: 'Borrow, use, return',
    desc: 'Pick up the item or get the service, then return it when done.',
    d: { cx: 18, cy: 18, tx: 61, ty: 47, gap: 3, dw: 216 },
  },
];

export function HowItWorks() {
  return (
    <section className="section section--how wrap" id="how">
      <SectionHead
        eyebrow="SIMPLE"
        eyebrowOn="mobile"
        gap={8}
        title="How Seculate works"
        subtitle="Get started in 3 simple steps."
      />

      <motion.ol
        className="steps"
        style={{ listStyle: 'none', padding: 0 }}
        variants={stagger(0.14)}
        initial="hidden"
        whileInView="show"
        viewport={viewport}
      >
        {steps.map((s) => (
          <motion.li
            key={s.n}
            className="step"
            variants={fadeUp}
            style={
              {
                '--cx': `${s.d.cx}px`,
                '--cy': `${s.d.cy}px`,
                '--tx': `${s.d.tx}px`,
                '--ty': `${s.d.ty}px`,
                '--gap': `${s.d.gap}px`,
                '--dw': `${s.d.dw}px`,
              } as CSSProperties
            }
          >
            <motion.span className="step__num" variants={pop}>
              <Art name="step-circle.svg" />
              <span>{s.n}</span>
            </motion.span>
            <div className="step__body">
              <h3 className="step__title">{s.title}</h3>
              <p className="step__desc">{s.desc}</p>
            </div>
          </motion.li>
        ))}
      </motion.ol>
    </section>
  );
}
