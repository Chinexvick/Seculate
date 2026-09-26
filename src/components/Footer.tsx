import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { Art } from '../lib/Art';
import { fadeIn, fadeUp, stagger } from '../lib/motion';
import { Socials } from './Socials';

const cols = [
  { title: 'Product', links: [['Services', '/#services'], ['Categories', '/#services'], ['Pricing', '/#pricing'], ['How it works', '/#how']] },
  { title: 'Company', links: [['About', '/about'], ['Contact', '/contact'], ['Careers', '/careers'], ['Partners', '/partners']] },
  { title: 'Resources', links: [['Help center', '/help'], ['Safety', '/safety'], ['Community', '/community'], ['Blog', '/blog']] },
];

export function Footer() {
  return (
    <motion.footer
      className="footer"
      variants={stagger(0.1)}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, amount: 0.15 }}
    >
      <div className="footer__inner">
        <motion.div className="footer__brand" variants={fadeUp}>
          <div className="footer__logo">
            <img className="footer__logo-mark" src="/brand/seculate-mark.svg" alt="" width={39} height={31} draggable={false} />
            <span className="footer__logo-name">Seculate</span>
          </div>
          <p className="footer__tag">Find, lend, rent and get things done.</p>
        </motion.div>

        <motion.div className="footer__badges" variants={fadeUp}>
          <a href="#" aria-label="Get it on Google Play">
            <Art name="badge-google.svg" alt="Get it on Google Play" />
          </a>
          <a href="#" aria-label="Download on the App Store">
            <Art name="badge-apple.svg" alt="Download on the App Store" />
          </a>
        </motion.div>

        <motion.div className="footer__cols" variants={stagger(0.1, 0.1)}>
          {cols.map((c) => (
            <motion.div key={c.title} className="footer__col" variants={fadeUp}>
              <h3>{c.title}</h3>
              <ul>
                {c.links.map(([label, href]) => (
                  <li key={label}>
                    <Link to={href}>{label}</Link>
                  </li>
                ))}
              </ul>
            </motion.div>
          ))}
        </motion.div>
      </div>

      <motion.div className="footer__bottom" variants={fadeIn}>
        <div className="footer__rule" />
        <div className="footer__legal">
          <span>© 2026 Seculate. All rights reserved.</span>
          <Socials />
          <span className="footer__legal-links">
            <Link to="/privacy">Privacy</Link> • <Link to="/terms">Terms</Link>
          </span>
        </div>
      </motion.div>
    </motion.footer>
  );
}
