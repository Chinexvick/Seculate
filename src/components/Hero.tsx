import { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { ease, fadeUp, stagger, wordReveal } from '../lib/motion';

const headline = 'Borrow and lend what you have. Get things done easily.'.split(' ');

export function Hero() {
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start start', 'end start'] });
  // Image drifts up slower than the page and gently scales — subtle parallax.
  const imageY = useTransform(scrollYProgress, [0, 1], [0, -70]);
  const imageScale = useTransform(scrollYProgress, [0, 1], [1, 1.06]);
  const textY = useTransform(scrollYProgress, [0, 1], [0, 40]);
  const textOpacity = useTransform(scrollYProgress, [0, 0.9], [1, 0.2]);

  return (
    <section className="hero" ref={ref} id="top">
      <motion.div className="hero__inner" style={{ y: textY, opacity: textOpacity }}>
        <motion.h1
          className="hero__title"
          variants={stagger(0.06, 0.15)}
          initial="hidden"
          animate="show"
          style={{ perspective: 600 }}
        >
          {headline.map((word, i) => (
            <motion.span key={i} className="word" variants={wordReveal}>
              {word + (i < headline.length - 1 ? ' ' : '')}
            </motion.span>
          ))}
        </motion.h1>

        <motion.p
          className="hero__lead"
          variants={fadeUp}
          initial="hidden"
          animate="show"
          transition={{ delay: 0.75, duration: 0.7, ease }}
        >
          Seculate connects you with people and businesses nearby. Access everyday essentials, trusted services, and
          flexible lending — all in one place.
        </motion.p>

        <motion.div
          className="hero__actions"
          variants={fadeUp}
          initial="hidden"
          animate="show"
          transition={{ delay: 0.9, duration: 0.7, ease }}
        >
          <motion.a href="#download" className="btn btn--green" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.97 }}>
            Download the app →
          </motion.a>
          <motion.a href="#services" className="btn btn--outline" whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.97 }}>
            <span className="hero__label-m">Explore Seculate</span>
            <span className="hero__label-d">Explore services</span>
          </motion.a>
        </motion.div>
      </motion.div>

      <motion.div
        className="hero__media"
        initial={{ opacity: 0, scale: 0.92, x: 40 }}
        animate={{ opacity: 1, scale: 1, x: 0 }}
        transition={{ delay: 0.3, duration: 1, ease }}
      >
        <motion.img
          src="/assets/shared/hero.webp"
          alt="Woman smiling at her phone, surrounded by a shirt, armchair, headphones and smart watch"
          width={1536}
          height={1024}
          style={{ y: imageY, scale: imageScale }}
          fetchPriority="high"
        />
      </motion.div>
    </section>
  );
}
