import { motion } from 'framer-motion';
import { PageHero } from '../components/PageHero';
import { Photo } from '../components/Photo';
import { CtaBand, FeatureGrid, Section } from '../components/ui';
import { photos } from '../content/photos';
import { fadeUp, stagger, viewport } from '../lib/motion';
import { usePageMeta } from '../lib/usePageMeta';

const offer = [
  { icon: 'search', title: 'Borrow', text: 'Get what you need for a day, a week or a project without paying full price to own it.' },
  { icon: 'box', title: 'Lend', text: 'Put the things sitting in your room, store or garage to work and earn from them safely.' },
  { icon: 'store', title: 'Rent', text: 'Businesses reach nearby customers who need their equipment, tools and gear.' },
  { icon: 'tools', title: 'Find services', text: 'Discover trusted local providers, from repairs and cleaning to events and more.' },
] as const;

const values = [
  { icon: 'shieldCheck', title: 'Trust comes first', text: 'Verification, ratings, reviews and secure escrow exist so strangers can become neighbours you can rely on.' },
  { icon: 'users', title: 'Community over consumption', text: 'The best item is often the one that already exists nearby. Sharing it is smarter than buying another.' },
  { icon: 'wallet', title: 'Fair and affordable', text: 'Pricing that makes sense for students, families, freelancers and small businesses alike, starting free.' },
  { icon: 'pin', title: 'Built for here', text: 'Designed around how people in Nigeria actually live, work, move and do business every day.' },
] as const;

export default function About() {
  usePageMeta('About us', 'Seculate helps people borrow, lend and rent what they have, and find trusted local services.');
  return (
    <>
      <PageHero
        eyebrow="ABOUT SECULATE"
        title="Making the things we already have work harder for everyone."
        lead="Seculate connects people and businesses nearby so you can borrow what you need, lend what you don’t, and get things done without the stress and cost of buying everything yourself."
        photo={photos.lagosTeam}
      />

      <Section eyebrow="OUR STORY" title="It started with a simple question">
        <div className="split">
          <motion.div className="prose" variants={stagger(0.08)} initial="hidden" whileInView="show" viewport={viewport}>
            <motion.p variants={fadeUp}>
              Why does every household buy its own drill, ladder, projector and party chairs, only to use them a few
              times a year? Across our cities, millions of useful things sit idle in rooms, stores and garages while
              someone a few streets away is paying full price for the very same thing, or going without.
            </motion.p>
            <motion.p variants={fadeUp}>
              At the same time, finding help you can trust is harder than it should be. Getting a reliable
              electrician, a camera for a weekend shoot or a generator for an event usually means endless calls,
              WhatsApp forwards and hoping the person who shows up is who they said they were.
            </motion.p>
            <motion.p variants={fadeUp}>
              Seculate brings all of that into one trusted place. Verified people and businesses list what they
              have. Everyone else can find it nearby, agree the details in-app, pay through secure escrow and rate the
              experience, so the next person knows exactly who they are dealing with.
            </motion.p>
          </motion.div>
          <motion.div
            className="split__media"
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={viewport}
            transition={{ duration: 0.8 }}
          >
            <Photo {...photos.friends} sizes="(min-width: 1024px) 520px, 100vw" />
          </motion.div>
        </div>
      </Section>

      <Section tone="mint" eyebrow="MISSION & VISION" title="Where we are going">
        <div className="mv">
          <Reveal2 label="Our mission" text="Help people save money, earn more and get things done by making it easy and safe to share what already exists around them." />
          <Reveal2 label="Our vision" text="Communities where access matters more than ownership, where everything you need is a short walk, a quick chat and a trusted exchange away." />
        </div>
      </Section>

      <Section eyebrow="WHAT YOU CAN DO" title="One app, four ways to get things done">
        <FeatureGrid items={[...offer]} cols={4} />
      </Section>

      <Section eyebrow="WHAT WE VALUE" title="The principles behind every decision">
        <FeatureGrid items={[...values]} cols={4} />
      </Section>

      <CtaBand
        title="Be part of the sharing economy."
        text="Join the people and businesses already borrowing, lending and earning on Seculate."
        secondary={{ label: 'Contact us', to: '/contact' }}
      />
    </>
  );
}

function Reveal2({ label, text }: { label: string; text: string }) {
  return (
    <motion.div
      className="mv__card"
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={viewport}
      transition={{ duration: 0.6 }}
    >
      <p className="mv__label">{label}</p>
      <p className="mv__text">{text}</p>
    </motion.div>
  );
}
