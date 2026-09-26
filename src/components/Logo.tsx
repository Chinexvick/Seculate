import { Art } from '../lib/Art';

export function Logo() {
  return (
    <a href="#top" className="logo" aria-label="Seculate home">
      <span className="logo__mark">
        <Art name="logo-circle.svg" />
        <span className="logo__s">S</span>
      </span>
      <span className="logo__name">Seculate</span>
    </a>
  );
}
