import { useState } from 'react';

export type PhotoSource = {
  /** Pexels photo id (responsive sizes are generated from it). */
  pexels?: number;
  /** Direct image URL, for photos that don't come from Pexels. */
  src?: string;
  alt: string;
  credit?: string;
};

type Props = PhotoSource & {
  className?: string;
  /** Rendered width hint for the browser, e.g. "(min-width: 1024px) 50vw, 100vw". */
  sizes?: string;
  priority?: boolean;
  /** Largest width to request from Pexels. */
  maxWidth?: number;
};

const pexelsUrl = (id: number, w: number) =>
  `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=${w}`;

/**
 * Stock photo with the Seculate colour grade (soft contrast, slightly desaturated,
 * green-tinted shadows and a navy vignette) so every image on the site feels like one set.
 * Falls back to a brand gradient if the image cannot load.
 */
export function Photo({ pexels, src, alt, className = '', sizes = '100vw', priority, maxWidth = 1800 }: Props) {
  const widths = [480, 800, 1200, 1800].filter((w) => w <= maxWidth);
  const [failed, setFailed] = useState(false);
  return (
    <span className={`photo ${failed ? 'photo--failed' : ''} ${className}`}>
      {!failed && (
        <img
          src={pexels ? pexelsUrl(pexels, Math.min(1200, widths[widths.length - 1])) : src}
          srcSet={pexels ? widths.map((w) => `${pexelsUrl(pexels, w)} ${w}w`).join(', ') : undefined}
          sizes={pexels ? sizes : undefined}
          alt={alt}
          loading={priority ? 'eager' : 'lazy'}
          decoding="async"
          onError={() => setFailed(true)}
        />
      )}
    </span>
  );
}
