import { motion } from 'framer-motion';
import { fadeUp, stagger, viewport } from '../lib/motion';
import { SectionHead } from './SectionHead';

const plans = [
  {
    name: 'Free',
    price: '₦0',
    desc: 'Perfect for getting started.',
    features: ['✓ Browse and search', '✓ Basic support', '✓ Limited settings'],
  },
  {
    name: 'Pro',
    price: '₦2,500',
    desc: 'For regular users and small businesses.',
    features: ['✓Unlimited access', '✓ Priority support', '✓ More visibility'],
    featured: true,
  },
  {
    name: 'Business',
    price: '₦7,500',
    desc: 'For active businesses.',
    features: ['✓ Everything in Pro', '✓ Advanced analytics', '✓ Featured settings'],
  },
];

export function Pricing() {
  return (
    <section className="section section--pricing wrap wrap--narrow" id="pricing">
      <SectionHead eyebrow="PLANS" gap={16} title="Flexible pricing" subtitle="Choose a plan that works for you." />

      <motion.div
        className="plans"
        variants={stagger(0.12)}
        initial="hidden"
        whileInView="show"
        viewport={viewport}
      >
        {plans.map((p) => (
          <motion.article
            key={p.name}
            className={`plan ${p.featured ? 'plan--featured' : ''}`}
            variants={fadeUp}
          >
            <h3 className="plan__name">{p.name}</h3>
            <div className="plan__price-row">
              <span className="plan__price">{p.price}</span>
              <span className="plan__per">/month</span>
            </div>
            <p className="plan__desc">{p.desc}</p>
            <ul className="plan__features">
              {p.features.map((f) => (
                <li key={f}>{f}</li>
              ))}
            </ul>
          </motion.article>
        ))}
      </motion.div>
    </section>
  );
}
