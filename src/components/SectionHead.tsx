import { Reveal } from './Reveal';

type Props = {
  eyebrow?: string;
  /** Show the eyebrow only on mobile / only on desktop (the two Figma frames differ). */
  eyebrowOn?: 'mobile' | 'desktop' | 'both';
  title: string;
  subtitle?: string;
  gap?: 8 | 12 | 16;
};

export function SectionHead({ eyebrow, eyebrowOn = 'both', title, subtitle, gap }: Props) {
  const eyebrowClass =
    eyebrowOn === 'mobile' ? 'only-mobile' : eyebrowOn === 'desktop' ? 'only-desktop' : '';
  return (
    <Reveal className={`head ${gap === 8 ? 'head--gap8' : gap === 16 ? 'head--gap16' : ''}`}>
      {eyebrow && <p className={`eyebrow ${eyebrowClass}`}>{eyebrow}</p>}
      <div className="head__text">
        <h2 className="title">{title}</h2>
        {subtitle && <p className="subtitle">{subtitle}</p>}
      </div>
    </Reveal>
  );
}
