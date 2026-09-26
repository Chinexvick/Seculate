import { MotionConfig, motion, useScroll, useSpring } from 'framer-motion';
import { Nav } from './components/Nav';
import { Hero } from './components/Hero';
import { Categories } from './components/Categories';
import { HowItWorks } from './components/HowItWorks';
import { Utility } from './components/Utility';
import { Pricing } from './components/Pricing';
import { Community } from './components/Community';
import { Cta } from './components/Cta';
import { Newsletter } from './components/Newsletter';
import { Footer } from './components/Footer';

export default function App() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 120, damping: 28, restDelta: 0.001 });

  return (
    // reducedMotion="user" turns off transform/layout animations for people who ask for less motion.
    <MotionConfig reducedMotion="user">
      <motion.div className="progress" style={{ scaleX }} aria-hidden />
      <div className="page">
        <Nav />
        <main>
          <Hero />
          <Categories />
          <HowItWorks />
          <Utility />
          <Pricing />
          <Community />
          <Cta />
          <Newsletter />
        </main>
        <Footer />
      </div>
    </MotionConfig>
  );
}
