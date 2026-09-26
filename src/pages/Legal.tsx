import { Link } from 'react-router-dom';
import { PageHero } from '../components/PageHero';
import { Section } from '../components/ui';
import { legal } from '../content/legal';
import { usePageMeta } from '../lib/usePageMeta';

export default function Legal({ doc }: { doc: 'privacy' | 'terms' }) {
  const d = legal[doc];
  usePageMeta(d.title);
  return (
    <>
      <PageHero eyebrow="LEGAL" title={d.title} lead={`Last updated ${d.updated}`} />
      <Section>
        <div className="legal">
          <nav className="legal__toc" aria-label="On this page">
            <p className="legal__toc-title">On this page</p>
            <ol>
              {d.sections.map((s) => (
                <li key={s.id}>
                  <a href={`#${s.id}`}>{s.title}</a>
                </li>
              ))}
            </ol>
            <p className="legal__other">
              {doc === 'privacy' ? <Link to="/terms">Read our Terms of Service →</Link> : <Link to="/privacy">Read our Privacy Policy →</Link>}
            </p>
          </nav>
          <article className="legal__body article">
            <p className="article__intro">{d.intro}</p>
            {d.sections.map((s, i) => (
              <section key={s.id} id={s.id}>
                <h2>
                  {i + 1}. {s.title}
                </h2>
                {s.body.map((b, j) =>
                  Array.isArray(b) ? (
                    <ul key={j}>
                      {b.map((li) => (
                        <li key={li}>{li}</li>
                      ))}
                    </ul>
                  ) : (
                    <p key={j}>
                      {b.includes('Contact page') ? (
                        <>
                          {b.split('Contact page')[0]}
                          <Link to="/contact">Contact page</Link>
                          {b.split('Contact page')[1]}
                        </>
                      ) : (
                        b
                      )}
                    </p>
                  ),
                )}
              </section>
            ))}
          </article>
        </div>
      </Section>
    </>
  );
}
