import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { motion, useScroll, useSpring } from 'framer-motion';
import { Icon } from '../components/Icon';
import { Photo } from '../components/Photo';
import { CtaBand, Section } from '../components/ui';
import { findPost, posts, type Block } from '../content/blog';
import { ease } from '../lib/motion';
import { usePageMeta } from '../lib/usePageMeta';
import { Meta, PostCard } from './Blog';
import NotFound from './NotFound';

export default function BlogPost() {
  const { slug = '' } = useParams();
  const post = findPost(slug);
  usePageMeta(post?.title, post?.excerpt);

  const { scrollYProgress } = useScroll();
  const progress = useSpring(scrollYProgress, { stiffness: 140, damping: 30 });

  if (!post) return <NotFound />;

  const related = posts.filter((p) => p.slug !== post.slug).slice(0, 3);

  return (
    <>
      <motion.div className="readbar" style={{ scaleX: progress }} aria-hidden />

      <article className="post">
        <header className="post__head">
          <motion.div
            className="post__head-inner"
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, ease }}
          >
            <Link to="/blog" className="post__back">
              <Icon name="arrowLeft" size={16} /> All articles
            </Link>
            <span className="bchip">{post.category}</span>
            <h1 className="post__title">{post.title}</h1>
            <p className="post__excerpt">{post.excerpt}</p>
            <div className="post__byline">
              <img src="/brand/seculate-mark.svg" alt="" width={36} height={29} />
              <span>
                <strong>{post.author}</strong>
                <Meta post={post} />
              </span>
            </div>
          </motion.div>
        </header>

        <motion.div
          className="post__cover"
          initial={{ opacity: 0, scale: 0.97 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.9, ease, delay: 0.1 }}
        >
          <Photo {...post.image} sizes="(min-width: 1024px) 1100px, 100vw" priority />
        </motion.div>

        <div className="post__layout">
          <aside className="post__share">
            <Share title={post.title} />
          </aside>
          <div className="article">
            {post.body.map((b, i) => (
              <BlockView key={i} block={b} />
            ))}
            <div className="post__end">
              <p>Found this helpful? Share it with someone who could use it.</p>
              <Share title={post.title} inline />
            </div>
          </div>
        </div>
      </article>

      <Section eyebrow="KEEP READING" title="More from the blog">
        <ul className="bgrid">
          {related.map((p) => (
            <li key={p.slug}>
              <PostCard post={p} />
            </li>
          ))}
        </ul>
      </Section>

      <CtaBand
        title="Ready to put these ideas to work?"
        text="Borrow what you need, lend what you don’t, and find trusted help nearby with Seculate."
      />
    </>
  );
}

function BlockView({ block: b }: { block: Block }) {
  switch (b.type) {
    case 'h2':
      return <h2>{b.text}</h2>;
    case 'h3':
      return <h3>{b.text}</h3>;
    case 'ul':
      return (
        <ul>
          {b.items.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
      );
    case 'ol':
      return (
        <ol>
          {b.items.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ol>
      );
    case 'quote':
      return <blockquote>{b.text}</blockquote>;
    case 'callout':
      return (
        <div className="callout">
          <span className="callout__icon">
            <Icon name="spark" size={18} />
          </span>
          <div>
            <p className="callout__title">{b.title}</p>
            <p>{b.text}</p>
          </div>
        </div>
      );
    default:
      return <p>{b.text}</p>;
  }
}

function Share({ title, inline }: { title: string; inline?: boolean }) {
  const [copied, setCopied] = useState(false);
  const url = typeof window !== 'undefined' ? window.location.href : '';
  const enc = encodeURIComponent;
  const links = [
    { label: 'Share on WhatsApp', href: `https://wa.me/?text=${enc(`${title} ${url}`)}`, text: 'WhatsApp' },
    { label: 'Share on X', href: `https://twitter.com/intent/tweet?text=${enc(title)}&url=${enc(url)}`, text: 'X' },
    { label: 'Share on Facebook', href: `https://www.facebook.com/sharer/sharer.php?u=${enc(url)}`, text: 'Facebook' },
    { label: 'Share on LinkedIn', href: `https://www.linkedin.com/sharing/share-offsite/?url=${enc(url)}`, text: 'LinkedIn' },
  ];

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      /* clipboard unavailable */
    }
  };

  return (
    <div className={`share ${inline ? 'share--inline' : ''}`}>
      {!inline && <span className="share__label">Share</span>}
      {links.map((l) => (
        <a key={l.text} href={l.href} target="_blank" rel="noopener noreferrer" aria-label={l.label} className="share__btn">
          {l.text}
        </a>
      ))}
      <button type="button" onClick={copy} className="share__btn" aria-label="Copy link">
        <Icon name={copied ? 'check' : 'link'} size={14} /> {copied ? 'Copied' : 'Copy link'}
      </button>
    </div>
  );
}
