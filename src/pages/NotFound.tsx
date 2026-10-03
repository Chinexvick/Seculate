import { Link } from 'react-router-dom';
import { Icon } from '../components/Icon';
import { usePageMeta } from '../lib/usePageMeta';
import { NOT_FOUND_META } from '../seo';

export default function NotFound() {
  usePageMeta(NOT_FOUND_META);
  return (
    <section className="nf">
      <p className="nf__code">404</p>
      <h1 className="phero__title">We couldn’t find that page.</h1>
      <p className="phero__lead">It may have moved, or the link might be incorrect.</p>
      <Link to="/" className="btn btn--green phero__btn">
        <Icon name="arrowLeft" size={16} /> Back to home
      </Link>
    </section>
  );
}
