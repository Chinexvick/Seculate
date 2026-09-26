import { Link } from 'react-router-dom';

export function Logo() {
  return (
    <Link to="/" className="logo" aria-label="Seculate home">
      <img className="logo__mark" src="/brand/seculate-mark.svg" alt="" width={39} height={31} draggable={false} />
      <span className="logo__name">Seculate</span>
    </Link>
  );
}
