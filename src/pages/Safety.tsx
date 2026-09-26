import { Link } from 'react-router-dom';
import { Icon, type IconName } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { CtaBand, FeatureGrid, Section } from '../components/ui';
import { usePageMeta } from '../lib/usePageMeta';

const built = [
  { icon: 'shieldCheck', title: 'Verified users', text: 'People and businesses on Seculate go through verification, so you know who you are dealing with.' },
  { icon: 'star', title: 'Ratings & reviews', text: 'Every completed exchange can be rated, building a public track record you can check before you commit.' },
  { icon: 'chat', title: 'In-app chat', text: 'Agree dates, prices and condition in the chat so there’s always a clear record of what was agreed.' },
  { icon: 'lock', title: 'Secure payments', text: 'Pay and get paid inside Seculate instead of sending money to strangers directly.' },
] as const;

const tips: { icon: IconName; title: string; items: string[] }[] = [
  {
    icon: 'search',
    title: 'When you borrow or rent',
    items: [
      'Check the lender’s verification, rating and recent reviews before you request.',
      'Confirm the price, dates, deposit (if any) and return details in the chat.',
      'Inspect the item at pickup, test it, and share photos in the chat before you leave.',
      'Return it on time and in the same condition. If you need longer, ask early.',
    ],
  },
  {
    icon: 'box',
    title: 'When you lend or list',
    items: [
      'Describe your item honestly, including any wear, faults or missing parts.',
      'Take clear photos before handover so the condition is documented.',
      'Review the borrower’s profile and reviews. You never have to accept a request.',
      'Only hand over the item once everything is confirmed in the app.',
    ],
  },
  {
    icon: 'pin',
    title: 'Meeting up in person',
    items: [
      'Meet in busy, well-lit public places during the day whenever you can.',
      'Tell a friend or family member where you’re going and who you’re meeting.',
      'For services at home, ask someone you trust to be around if possible.',
      'Trust your instincts. If something feels wrong, leave and report it.',
    ],
  },
];

const redFlags = [
  'Asking you to pay or chat outside the Seculate app',
  'Prices that seem far too good to be true',
  'Pressure to decide or pay immediately',
  'Refusing to meet, show the item or share clear photos',
  'Asking for one-time codes, passwords or bank PINs',
  'Profiles with no photo, no reviews and a vague description',
];

export default function Safety() {
  usePageMeta('Safety', 'How Seculate helps keep borrowing, lending and local services safe, plus practical safety tips.');
  return (
    <>
      <PageHero
        eyebrow="TRUST & SAFETY"
        title="Safe exchanges, every time."
        lead="Sharing only works when people feel safe. Here’s what we build into Seculate to protect you, and simple habits that keep every exchange smooth."
      />

      <Section eyebrow="BUILT IN" title="How Seculate helps protect you">
        <FeatureGrid items={[...built]} cols={4} />
      </Section>

      <Section tone="mint" eyebrow="SAFETY TIPS" title="Simple habits for safer exchanges">
        <div className="tips">
          {tips.map((t) => (
            <div key={t.title} className="tip card">
              <h3 className="tip__title">
                <span className="fcard__icon fcard__icon--sm">
                  <Icon name={t.icon} size={18} />
                </span>
                {t.title}
              </h3>
              <ul className="checklist">
                {t.items.map((i) => (
                  <li key={i}>
                    <span className="checklist__tick">
                      <Icon name="check" size={14} />
                    </span>
                    {i}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </Section>

      <Section eyebrow="STAY ALERT" title="Red flags to watch out for">
        <div className="flags">
          {redFlags.map((f) => (
            <div key={f} className="flag">
              <span className="flag__icon">
                <Icon name="alert" size={18} />
              </span>
              {f}
            </div>
          ))}
        </div>
      </Section>

      <Section>
        <div className="report card">
          <span className="empty__icon">
            <Icon name="flag" size={26} />
          </span>
          <div>
            <h2 className="card__title">If something goes wrong</h2>
            <p>
              Stop the exchange, keep all communication in the app, and report the user or listing using the report
              option in the app or through our <Link to="/contact">contact form</Link> (choose “Report a safety
              concern”). If you are ever in immediate danger, contact local emergency services first.
            </p>
          </div>
        </div>
      </Section>

      <CtaBand
        title="Have a question about safety?"
        text="Our Help center covers verification, payments, reporting and more."
        primary={{ label: 'Visit the Help center', to: '/help#safety' }}
      />
    </>
  );
}
