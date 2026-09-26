import type { CSSProperties } from 'react';

type ArtProps = {
  /** File name that exists in both /assets/desktop and /assets/mobile. */
  name: string;
  alt?: string;
  className?: string;
  style?: CSSProperties;
};

/**
 * Renders the Figma export that belongs to the active layout.
 * Mobile and desktop frames use different sizes of the same artwork, so the
 * right file is picked with <picture> (same 1024px breakpoint as the CSS).
 * The SVGs keep their intrinsic width/height attributes.
 */
export function Art({ name, alt = '', className, style }: ArtProps) {
  return (
    <picture>
      <source media="(min-width: 1024px)" srcSet={`/assets/desktop/${name}`} />
      <img src={`/assets/mobile/${name}`} alt={alt} className={className} style={style} draggable={false} />
    </picture>
  );
}
