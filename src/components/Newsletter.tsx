import { useState, type FormEvent } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { ease, fadeUp, stagger, viewport } from '../lib/motion';

export function Newsletter() {
  const [email, setEmail] = useState('');
  const [done, setDone] = useState(false);

  // TODO: send `email` to the newsletter provider once one is chosen.
  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    setDone(true);
  };

  return (
    <section className="section section--newsletter wrap" id="newsletter">
      <motion.div
        className="newsletter"
        variants={stagger(0.1)}
        initial="hidden"
        whileInView="show"
        viewport={viewport}
      >
        <motion.div className="newsletter__copy" variants={fadeUp}>
          <p className="eyebrow">NEWSLETTER</p>
          <h2 className="newsletter__title">Subscribe to our newsletter</h2>
          <p className="newsletter__text">Get new features, tips and offers from Seculate. No spam, unsubscribe anytime.</p>
        </motion.div>

        <motion.div className="newsletter__action" variants={fadeUp}>
          <AnimatePresence mode="wait" initial={false}>
            {done ? (
              <motion.p
                key="done"
                className="newsletter__done"
                role="status"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, ease }}
              >
                ✓ Thanks for subscribing! We'll be in touch.
              </motion.p>
            ) : (
              <motion.form
                key="form"
                className="newsletter__form"
                onSubmit={onSubmit}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.25 }}
              >
                <label htmlFor="newsletter-email" className="sr-only">
                  Email address
                </label>
                <input
                  id="newsletter-email"
                  type="email"
                  required
                  autoComplete="email"
                  placeholder="Enter your email"
                  className="newsletter__input"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
                <motion.button
                  type="submit"
                  className="btn btn--green newsletter__btn"
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                >
                  Subscribe
                </motion.button>
              </motion.form>
            )}
          </AnimatePresence>
        </motion.div>
      </motion.div>
    </section>
  );
}
