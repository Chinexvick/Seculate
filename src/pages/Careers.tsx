import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { FeatureGrid, LeadForm, Section } from '../components/ui';
import { photos } from '../content/photos';
import { usePageMeta } from '../lib/usePageMeta';

const why = [
  { icon: 'growth', title: 'Real impact', text: 'Your work directly helps people save money, earn income and access what they need.' },
  { icon: 'spark', title: 'Ownership', text: 'Small team, big problems. You’ll own meaningful work from idea to launch.' },
  { icon: 'book', title: 'Learn fast', text: 'We share knowledge openly, give honest feedback and grow together.' },
  { icon: 'heart', title: 'People first', text: 'We build for our community, and we treat each other the same way.' },
] as const;

const principles = [
  ['Start with the user', 'We talk to borrowers, lenders and businesses constantly. Their problems set our priorities.'],
  ['Earn trust every day', 'Trust is our product. We are honest with users and with each other, even when it’s hard.'],
  ['Ship, learn, improve', 'We prefer small steps we can learn from over big plans we never test.'],
  ['Keep it simple', 'Clear products, clear writing, clear decisions. Simple is harder, and better.'],
];

export default function Careers() {
  usePageMeta('Careers', 'Help build the trusted way to borrow, lend and get things done. Work with Seculate.');
  return (
    <>
      <PageHero
        eyebrow="CAREERS"
        title="Help us build a smarter way to share."
        lead="We’re building the trusted marketplace for borrowing, lending and local services. If you care about solving real everyday problems for real people, you’ll feel at home here."
        photo={photos.meeting}
      >
        <a href="#apply" className="btn btn--green phero__btn">
          Send your application <Icon name="arrow" size={16} />
        </a>
      </PageHero>

      <Section eyebrow="WHY SECULATE" title="Work that matters, with people who care">
        <FeatureGrid items={[...why]} cols={4} />
      </Section>

      <Section tone="mint" eyebrow="HOW WE WORK" title="Our working principles">
        <ol className="principles">
          {principles.map(([t, d], i) => (
            <li key={t} className="principle">
              <span className="principle__num">{String(i + 1).padStart(2, '0')}</span>
              <div>
                <h3>{t}</h3>
                <p>{d}</p>
              </div>
            </li>
          ))}
        </ol>
      </Section>

      <Section id="apply" eyebrow="OPEN ROLES" title="Join the team">
        <div className="careers">
          <div className="empty card">
            <span className="empty__icon">
              <Icon name="briefcase" size={28} />
            </span>
            <h3>No open roles right now</h3>
            <p>
              We’re not hiring for a specific position at the moment, but we’re always happy to meet talented people.
              Send a general application and we’ll reach out when there’s a fit.
            </p>
          </div>
          <div className="card">
            <h2 className="card__title">General application</h2>
            <LeadForm
              fields={[
                { name: 'name', label: 'Full name', placeholder: 'Your name' },
                { name: 'email', label: 'Email address', type: 'email', placeholder: 'you@example.com' },
                {
                  name: 'area',
                  label: 'Area of interest',
                  type: 'select',
                  placeholder: 'Choose an area',
                  options: ['Engineering', 'Product & Design', 'Operations & Community', 'Marketing & Growth', 'Customer Support', 'Other'],
                },
                { name: 'link', label: 'Portfolio, LinkedIn or CV link', type: 'url', placeholder: 'https://', required: false },
                { name: 'message', label: 'Tell us about yourself', type: 'textarea', full: true, placeholder: 'What would you love to work on at Seculate?' },
              ]}
              submitLabel="Submit application"
              successTitle="Application received!"
              successText="Thank you for your interest in Seculate. We’ll be in touch if there’s a role that fits."
            />
          </div>
        </div>
      </Section>
    </>
  );
}
