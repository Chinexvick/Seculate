import { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';

export function Cta() {
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start end', 'start 0.6'] });
  const scale = useTransform(scrollYProgress, [0, 1], [0.92, 1]);
  const opacity = useTransform(scrollYProgress, [0, 0.6], [0.4, 1]);
  const btnY = useTransform(scrollYProgress, [0, 1], [30, 0]);

  return (
    <section className="section section--cta wrap" id="download" ref={ref}>
      <motion.div className="cta" style={{ scale, opacity }}>
        <h2 className="cta__title">Ready to get started?</h2>
        <p className="cta__text">Download Seculate and get more done with less hassle.</p>
        <motion.a
          href="#download"
          className="btn btn--white cta__btn"
          style={{ y: btnY }}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.97 }}
        >
          Download the app →
        </motion.a>
      </motion.div>
    </section>
  );
}
