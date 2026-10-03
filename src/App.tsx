import { MotionConfig, motion, useScroll, useSpring } from 'framer-motion';
import { Route, Routes } from 'react-router-dom';
import { Nav } from './components/Nav';
import { Newsletter } from './components/Newsletter';
import { Footer } from './components/Footer';
import { ScrollManager } from './components/ScrollManager';
import Home from './pages/Home';
import About from './pages/About';
import Contact from './pages/Contact';
import Careers from './pages/Careers';
import Partners from './pages/Partners';
import Help from './pages/Help';
import Safety from './pages/Safety';
import CommunityPage from './pages/CommunityPage';
import Blog from './pages/Blog';
import BlogPost from './pages/BlogPost';
import Legal from './pages/Legal';
import NotFound from './pages/NotFound';

/** The whole site. The router is supplied by the caller: BrowserRouter in the browser, StaticRouter at build time. */
export default function App() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 120, damping: 28, restDelta: 0.001 });

  return (
    <>
      <ScrollManager />
      {/* reducedMotion="user" turns off transform/layout animations for people who ask for less motion. */}
      <MotionConfig reducedMotion="user">
        <motion.div className="progress" style={{ scaleX }} aria-hidden />
        <div className="page">
          <Nav />
          <main>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/about" element={<About />} />
              <Route path="/contact" element={<Contact />} />
              <Route path="/careers" element={<Careers />} />
              <Route path="/partners" element={<Partners />} />
              <Route path="/help" element={<Help />} />
              <Route path="/safety" element={<Safety />} />
              <Route path="/community" element={<CommunityPage />} />
              <Route path="/blog" element={<Blog />} />
              <Route path="/blog/:slug" element={<BlogPost />} />
              <Route path="/privacy" element={<Legal doc="privacy" />} />
              <Route path="/terms" element={<Legal doc="terms" />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </main>
          <Newsletter />
          <Footer />
        </div>
      </MotionConfig>
    </>
  );
}
