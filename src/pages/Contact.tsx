import { Link } from 'react-router-dom';
import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { LeadForm, Section } from '../components/ui';
import { usePageMeta } from '../lib/usePageMeta';

const shortcuts = [
  { icon: 'book', title: 'Help center', text: 'Quick answers about borrowing, listing, plans and your account.', to: '/help', cta: 'Browse answers' },
  { icon: 'shieldCheck', title: 'Safety concern', text: 'Something doesn’t feel right? Read our safety guidance or report it below.', to: '/safety', cta: 'Safety tips' },
  { icon: 'handshake', title: 'Partnerships', text: 'Run a business, campus group or community? Let’s grow together.', to: '/partners', cta: 'Partner with us' },
] as const;

export default function Contact() {
  usePageMeta('Contact us', 'Get in touch with the Seculate team for support, partnerships, press or feedback.');
  return (
    <>
      <PageHero
        eyebrow="CONTACT"
        title="We’d love to hear from you."
        lead="Questions, feedback, partnership ideas or something that needs our attention: send us a message and the right person on our team will get back to you."
      />

      <Section>
        <div className="contact">
          <div className="contact__form card">
            <h2 className="card__title">Send us a message</h2>
            <LeadForm
              fields={[
                { name: 'name', label: 'Full name', placeholder: 'Ada Okafor' },
                { name: 'email', label: 'Email address', type: 'email', placeholder: 'you@example.com' },
                {
                  name: 'topic',
                  label: 'What is it about?',
                  type: 'select',
                  full: true,
                  placeholder: 'Choose a topic',
                  options: ['General question', 'Help with my account', 'Billing', 'Report a safety concern', 'Partnerships', 'Press & media', 'Feedback & ideas'],
                },
                { name: 'message', label: 'Message', type: 'textarea', full: true, placeholder: 'Tell us how we can help…' },
              ]}
              submitLabel="Send message"
              successTitle="Message sent!"
              successText="Thanks for reaching out. Our team will get back to you by email as soon as possible."
            />
          </div>

          <aside className="contact__side">
            {shortcuts.map((s) => (
              <Link key={s.title} to={s.to} className="scard">
                <span className="fcard__icon">
                  <Icon name={s.icon} />
                </span>
                <span className="scard__body">
                  <span className="scard__title">{s.title}</span>
                  <span className="scard__text">{s.text}</span>
                  <span className="scard__cta">
                    {s.cta} <Icon name="arrow" size={14} />
                  </span>
                </span>
              </Link>
            ))}
            <a className="scard scard--social" href="https://www.instagram.com/seculate.ng" target="_blank" rel="noopener noreferrer">
              <span className="fcard__icon">
                <Icon name="chat" />
              </span>
              <span className="scard__body">
                <span className="scard__title">Say hi on Instagram</span>
                <span className="scard__text">Follow and message us at @seculate.ng</span>
              </span>
            </a>
          </aside>
        </div>
      </Section>
    </>
  );
}
