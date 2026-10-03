import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { Icon } from '../components/Icon';
import { PageHero } from '../components/PageHero';
import { Socials } from '../components/Socials';
import { CtaBand, FeatureGrid, Section } from '../components/ui';
import { photos } from '../content/photos';
import { fadeUp, stagger, viewport } from '../lib/motion';
import { usePageMeta } from '../lib/usePageMeta';

const guidelines = [
  { icon: 'eye', title: 'Be honest', text: 'Describe items and services truthfully, with real photos and any faults clearly stated.' },
  { icon: 'heart', title: 'Be respectful', text: 'Treat every borrower, lender and provider the way you would like to be treated.' },
  { icon: 'clock', title: 'Be reliable', text: 'Show up on time, return items when agreed, and communicate early if plans change.' },
  { icon: 'chat', title: 'Keep it on Seculate', text: 'Chat and pay in the app so there is always a record, and we can help if needed.' },
  { icon: 'star', title: 'Leave fair reviews', text: 'Honest, specific reviews help everyone decide who to trust.' },
  { icon: 'flag', title: 'Speak up', text: 'Report anything unsafe or suspicious. Looking out for each other keeps the community strong.' },
] as const;

const stories = [
  { name: 'Tunde A.', role: 'Student', avatar: 'tunde', text: 'Seculate helped me get a laptop for my project without spending a fortune.' },
  { name: 'Fatima B.', role: 'Small Business Owner', avatar: 'fatima', text: 'I’ve rented a few items for my business and the process is always smooth.' },
  { name: 'Chinedu K.', role: 'Freelancer', avatar: 'chinedu', text: 'Great platform! I listed a camera I don’t use often and got it rented quickly.' },
];

export default function CommunityPage() {
  usePageMeta();
  return (
    <>
      <PageHero
        eyebrow="COMMUNITY"
        title="Neighbours helping neighbours get things done."
        lead="Seculate is built by the people who use it: students, families, freelancers and small businesses sharing what they have and helping each other save, earn and grow."
        photo={photos.friends}
      />

      <Section eyebrow="GUIDELINES" title="How we treat each other">
        <FeatureGrid items={[...guidelines]} cols={3} />
      </Section>

      <Section tone="mint" eyebrow="MEMBER STORIES" title="What our community says">
        <motion.ul className="stories" variants={stagger(0.1)} initial="hidden" whileInView="show" viewport={viewport}>
          {stories.map((s) => (
            <motion.li key={s.name} className="story card" variants={fadeUp}>
              <span className="story__stars" aria-label="5 out of 5 stars">
                {Array.from({ length: 5 }, (_, i) => (
                  <Icon key={i} name="star" size={16} />
                ))}
              </span>
              <p className="story__text">“{s.text}”</p>
              <div className="story__who">
                <img src={`/assets/desktop/avatar-${s.avatar}.png`} alt="" width={40} height={40} />
                <span>
                  <strong>{s.name}</strong>
                  <span>{s.role}</span>
                </span>
              </div>
            </motion.li>
          ))}
        </motion.ul>
      </Section>

      <Section eyebrow="GET INVOLVED" title="Join the conversation">
        <div className="involve">
          <div className="involve__card card">
            <h3 className="card__title">Follow Seculate</h3>
            <p>Tips, member spotlights, new features and giveaways. Follow us and say hello.</p>
            <div className="involve__socials">
              <Socials />
            </div>
          </div>
          <div className="involve__card card">
            <h3 className="card__title">Read the blog</h3>
            <p>Guides on saving money, earning from what you own and staying safe while you share.</p>
            <Link to="/blog" className="textlink">
              Visit the blog <Icon name="arrow" size={14} />
            </Link>
          </div>
          <div className="involve__card card">
            <h3 className="card__title">Bring Seculate to your group</h3>
            <p>Run a campus association, estate or community group? Let’s make sharing easier for your members.</p>
            <Link to="/partners" className="textlink">
              Partner with us <Icon name="arrow" size={14} />
            </Link>
          </div>
        </div>
      </Section>

      <CtaBand title="Your community is already on Seculate." text="Download the app and start borrowing, lending and earning today." />
    </>
  );
}
