import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { FeatureGrid, LeadForm, Section } from '../components/ui';
import { photos } from '../content/photos';
import { usePageMeta } from '../lib/usePageMeta';

const types = [
  { icon: 'store', title: 'Rental businesses', text: 'Equipment, event, camera and vehicle rental companies reaching new customers nearby.' },
  { icon: 'tools', title: 'Service providers', text: 'Technicians, cleaners, artisans and professionals getting discovered by people who need them.' },
  { icon: 'box', title: 'Retailers & brands', text: 'Let customers try before they buy, or offer your products for rent.' },
  { icon: 'school', title: 'Campuses & communities', text: 'Student unions, estates and associations that want members to share and save.' },
  { icon: 'truck', title: 'Logistics', text: 'Delivery and dispatch partners helping items move quickly and safely.' },
  { icon: 'shield', title: 'Payments & protection', text: 'Fintech and protection partners making every exchange more secure.' },
] as const;

const benefits = [
  'Reach verified customers in your area who are actively looking',
  'Featured placement and visibility for your listings',
  'Tools to manage listings, requests and custom offers',
  'Ratings and reviews that build your reputation',
  'A dedicated point of contact at Seculate',
];

const steps = [
  ['Tell us about you', 'Fill in the short form below with your business and what you have in mind.'],
  ['Let’s talk', 'We’ll set up a call to understand your goals and design the right partnership.'],
  ['Launch together', 'We get you set up, listed and promoted to the Seculate community.'],
];

export default function Partners() {
  usePageMeta('Partner with us', 'Grow your business with Seculate: reach verified customers nearby who need what you offer.');
  return (
    <>
      <PageHero
        eyebrow="PARTNERS"
        title="Grow with the community that shares."
        lead="Whether you rent equipment, offer a service or bring people together, Seculate connects you with verified customers nearby who need exactly what you have."
        photo={photos.shopOwner}
      >
        <a href="#partner-form" className="btn btn--green phero__btn">
          Become a partner <Icon name="arrow" size={16} />
        </a>
      </PageHero>

      <Section eyebrow="WHO WE WORK WITH" title="Partnerships for every kind of business">
        <FeatureGrid items={[...types]} cols={3} />
      </Section>

      <Section tone="navy">
        <div className="benefits">
          <div>
            <p className="eyebrow eyebrow--light">WHY PARTNER</p>
            <h2 className="psec__title psec__title--light">What you get as a Seculate partner</h2>
          </div>
          <ul className="checklist checklist--light">
            {benefits.map((b) => (
              <li key={b}>
                <span className="checklist__tick">
                  <Icon name="check" size={14} />
                </span>
                {b}
              </li>
            ))}
          </ul>
        </div>
      </Section>

      <Section eyebrow="HOW IT WORKS" title="Three steps to get started">
        <ol className="principles principles--3">
          {steps.map(([t, d], i) => (
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

      <Section id="partner-form" tone="mint" eyebrow="GET IN TOUCH" title="Let’s build something together" center>
        <div className="card card--narrow">
          <LeadForm
            fields={[
              { name: 'name', label: 'Your name', placeholder: 'Full name' },
              { name: 'business', label: 'Business or organisation', placeholder: 'Company name' },
              { name: 'email', label: 'Work email', type: 'email', placeholder: 'you@company.com' },
              { name: 'phone', label: 'Phone number', type: 'tel', placeholder: '+234', required: false },
              {
                name: 'type',
                label: 'Partnership type',
                type: 'select',
                full: true,
                placeholder: 'Choose one',
                options: [...types.map((t) => t.title as string), 'Something else'],
              },
              { name: 'message', label: 'What do you have in mind?', type: 'textarea', full: true, placeholder: 'Tell us about your business and goals…' },
            ]}
            submitLabel="Send partnership request"
            successTitle="Request received!"
            successText="Thanks for your interest in partnering with Seculate. Our partnerships team will reach out soon."
          />
        </div>
      </Section>
    </>
  );
}
