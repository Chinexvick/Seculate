import { motion } from 'framer-motion';
import { fadeUp, stagger, viewport } from '../lib/motion';
import { SectionHead } from './SectionHead';

const plans = [
  {
    name: '🔰 On Code',
    price: '₦0',
    features: ['✓ Item Limit: List up to 3 items/month', '✓ Duration: 2 weeks', '✓ Visibility: Standard'],
  },
  {
    name: '✅ Active',
    price: '₦500',
    features: ['✓ Item Limit: List up to 5 items/month', '✓ Duration: 30 days', '✓ Visibility: Standard'],
  },
  {
    name: '🚀 Hustler',
    price: '₦1,500',
    features: [
      '✓ Item Limit: List up to 10 items/month',
      '✓ Duration: 60 days',
      '✓ Visibility: Standard + Featured once a week',
    ],
    featured: true,
  },
  {
    name: '👑 Top Lender',
    price: '₦5,000',
    features: [
      '✓ Item Limit: Unlimited',
      '✓ Duration: Unlimited',
      '✓ Visibility: Top Priority',
      '✓ Access to Private Requests',
      '✓ Custom Offers',
      '✓ Priority Support',
    ],
  },
];

export function Pricing() {
  return (
    <section className="section section--pricing wrap wrap--narrow" id="pricing">
      <SectionHead eyebrow="PLANS" gap={16} title="Pricing plans" subtitle="List for free. Upgrade to post more items and get noticed." />

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
