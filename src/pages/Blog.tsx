import { useState } from 'react';
import { Link } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { Photo } from '../components/Photo';
import { Section } from '../components/ui';
import { formatDate, posts, readingTime, type Post } from '../content/blog';
import { ease } from '../lib/motion';
import { usePageMeta } from '../lib/usePageMeta';

const categories = ['All', ...Array.from(new Set(posts.map((p) => p.category)))];

export default function Blog() {
  usePageMeta('Blog', 'Guides and stories on saving money, earning from what you own and staying safe while you share.');
  const [cat, setCat] = useState('All');
  const [featured, ...rest] = posts;
  const filtered = cat === 'All' ? rest : posts.filter((p) => p.category === cat);

  return (
    <>
      <PageHero
        eyebrow="THE SECULATE BLOG"
        title="Smarter ways to save, earn and share."
        lead="Practical guides and ideas for getting more done with less: borrowing wisely, lending safely, finding reliable help and building a community that shares."
      />

      {cat === 'All' && (
        <Section>
          <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, ease }}>
            <Link to={`/blog/${featured.slug}`} className="bfeat">
              <Photo {...featured.image} className="bfeat__media" sizes="(min-width: 1024px) 640px, 100vw" priority />
              <div className="bfeat__body">
                <span className="bchip">Featured · {featured.category}</span>
                <h2 className="bfeat__title">{featured.title}</h2>
                <p className="bfeat__excerpt">{featured.excerpt}</p>
                <Meta post={featured} />
                <span className="textlink">
                  Read article <Icon name="arrow" size={14} />
                </span>
              </div>
            </Link>
          </motion.div>
        </Section>
      )}

      <Section>
        <div className="bfilter" role="tablist" aria-label="Filter by category">
          {categories.map((c) => (
            <button
              key={c}
              type="button"
              role="tab"
              aria-selected={cat === c}
              className={`bfilter__chip ${cat === c ? 'is-active' : ''}`}
              onClick={() => setCat(c)}
            >
              {c}
            </button>
          ))}
        </div>

        {/* Four cards read better as a 2x2 grid than 3 + 1. */}
        <motion.ul className={`bgrid ${filtered.length === 4 || filtered.length === 2 ? 'bgrid--2' : ''}`} layout>
          <AnimatePresence mode="popLayout">
            {filtered.map((p, i) => (
              <motion.li
                key={p.slug}
                layout
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0, transition: { duration: 0.5, delay: i * 0.06, ease } }}
                exit={{ opacity: 0, scale: 0.96, transition: { duration: 0.2 } }}
              >
                <PostCard post={p} />
              </motion.li>
            ))}
          </AnimatePresence>
        </motion.ul>
      </Section>
    </>
  );
}

export function PostCard({ post }: { post: Post }) {
  return (
    <Link to={`/blog/${post.slug}`} className="bcard">
      <span className="bcard__media">
        <Photo {...post.image} sizes="(min-width: 1024px) 400px, 100vw" />
        <span className="bchip bchip--float">{post.category}</span>
      </span>
      <span className="bcard__body">
        <span className="bcard__title">{post.title}</span>
        <span className="bcard__excerpt">{post.excerpt}</span>
        <Meta post={post} />
      </span>
    </Link>
  );
}

export function Meta({ post }: { post: Post }) {
  return (
    <span className="bmeta">
      <span>{formatDate(post.date)}</span>
      <span aria-hidden>·</span>
      <span>{readingTime(post)} min read</span>
    </span>
  );
}
