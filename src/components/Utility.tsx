import { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { Art } from '../lib/Art';
import { fadeUp, pop, scaleIn, stagger, viewport } from '../lib/motion';

const items = [
  { title: 'Affordable', desc: 'Save money by borrowing instead of buying.' },
  { title: 'Trusted', desc: 'Verified users, ratings and secure payments.' },
  { title: 'Local', desc: 'Support people and businesses near you.' },
];

export function Utility() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start end', 'end start'] });
  const rotate = useTransform(scrollYProgress, [0, 1], [-40, 60]);

  return (
    <section className="section section--utility utility-wrap">
      <motion.div
        ref={ref}
        className="utility"
        variants={scaleIn}
        initial="hidden"
        whileInView="show"
        viewport={viewport}
      >
        <motion.div className="utility__head" variants={stagger(0.1)}>
          <h2 className="utility__title">
            More access. Less waste.
            <motion.span style={{ rotate, display: 'inline-flex' }}>
              <Art name="sparkle.svg" />
            </motion.span>
          </h2>
          <p className="utility__sub">A smarter way to get things done.</p>
        </motion.div>

        <motion.ul className="utility__list" variants={stagger(0.12, 0.25)}>
          {items.map((it) => (
            <motion.li key={it.title} className="utility__item" variants={fadeUp}>
              <motion.span className="utility__check" variants={pop}>
                <Art name="check-circle.svg" />
                <span>✓</span>
              </motion.span>
              <div className="utility__text">
                <strong>{it.title}</strong>
                <span>{it.desc}</span>
              </div>
            </motion.li>
          ))}
        </motion.ul>
      </motion.div>
    </section>
  );
}
