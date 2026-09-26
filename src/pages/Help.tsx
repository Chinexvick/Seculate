import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { FaqList, Section } from '../components/ui';
import { helpTopics } from '../content/help';
import { fadeUp, stagger } from '../lib/motion';
import { usePageMeta } from '../lib/usePageMeta';

export default function Help() {
  usePageMeta('Help center', 'Answers to common questions about borrowing, lending, plans, safety and your Seculate account.');
  const [query, setQuery] = useState('');
  const q = query.trim().toLowerCase();

  const results = useMemo(
    () =>
      helpTopics
        .map((t) => ({
          ...t,
          faqs: q ? t.faqs.filter((f) => `${f.q} ${f.a}`.toLowerCase().includes(q)) : t.faqs,
        }))
        .filter((t) => t.faqs.length > 0),
    [q],
  );

  return (
    <>
      <PageHero
        eyebrow="HELP CENTER"
        title="How can we help?"
        lead="Search our answers or pick a topic below."
      >
        <label className="hsearch">
          <Icon name="search" size={18} />
          <span className="sr-only">Search help articles</span>
          <input
            type="search"
            placeholder="Search e.g. “return”, “plans”, “report”"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </label>
      </PageHero>

      {!q && (
        <Section>
          <motion.ul className="topics" variants={stagger(0.06)} initial="hidden" animate="show">
            {helpTopics.map((t) => (
              <motion.li key={t.id} variants={fadeUp}>
                <a href={`#${t.id}`} className="topic">
                  <span className="fcard__icon">
                    <Icon name={t.icon} />
                  </span>
                  <span className="topic__title">{t.title}</span>
                  <span className="topic__text">{t.blurb}</span>
                  <span className="topic__count">{t.faqs.length} articles</span>
                </a>
              </motion.li>
            ))}
          </motion.ul>
        </Section>
      )}

      <Section>
        {results.length === 0 ? (
          <div className="empty card">
            <span className="empty__icon">
              <Icon name="search" size={28} />
            </span>
            <h3>No results for “{query}”</h3>
            <p>
              Try a different word, or <Link to="/contact">contact our team</Link> and we’ll help you directly.
            </p>
          </div>
        ) : (
          <div className="hgroups">
            {results.map((t) => (
              <div key={t.id} id={t.id} className="hgroup">
                <h2 className="hgroup__title">
                  <span className="fcard__icon fcard__icon--sm">
                    <Icon name={t.icon} size={18} />
                  </span>
                  {t.title}
                </h2>
                <FaqList key={q} items={t.faqs} />
              </div>
            ))}
          </div>
        )}
      </Section>

      <Section>
        <div className="stillneed card">
          <div>
            <h2 className="card__title">Still need help?</h2>
            <p>Our team is here for you. Send us a message and we’ll get back to you as soon as we can.</p>
          </div>
          <Link to="/contact" className="btn btn--green stillneed__btn">
            Contact support <Icon name="arrow" size={16} />
          </Link>
        </div>
      </Section>
    </>
  );
}
