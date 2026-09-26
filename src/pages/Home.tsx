import { Hero } from '../components/Hero';
import { Categories } from '../components/Categories';
import { HowItWorks } from '../components/HowItWorks';
import { Utility } from '../components/Utility';
import { Pricing } from '../components/Pricing';
import { ItemMarquee } from '../components/ItemMarquee';
import { Community } from '../components/Community';
import { Cta } from '../components/Cta';
import { usePageMeta } from '../lib/usePageMeta';

export default function Home() {
  usePageMeta();
  return (
    <>
      <Hero />
      <Categories />
      <HowItWorks />
      <Utility />
      <ItemMarquee />
      <Pricing />
      <Community />
      <Cta />
    </>
  );
}
