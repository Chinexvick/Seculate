import { useState } from 'react';

export type PhotoSource = {
  /** Pexels photo id. */
  pexels: number;
  alt: string;
  credit?: string;
};

type Props = PhotoSource & {
  className?: string;
  /** Rendered width hint for the browser, e.g. "(min-width: 1024px) 50vw, 100vw". */
  sizes?: string;
  priority?: boolean;
};

const src = (id: number, w: number) =>
  `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=${w}`;

/**
 * Stock photo with the Seculate colour grade (soft contrast, slightly desaturated,
 * green-tinted shadows and a navy vignette) so every image on the site feels like one set.
 * Falls back to a brand gradient if the image cannot load.
 */
export function Photo({ pexels, alt, className = '', sizes = '100vw', priority }: Props) {
  const [failed, setFailed] = useState(false);
  return (
    <span className={`photo ${failed ? 'photo--failed' : ''} ${className}`}>
      {!failed && (
        <img
          src={src(pexels, 1200)}
          srcSet={[480, 800, 1200, 1800].map((w) => `${src(pexels, w)} ${w}w`).join(', ')}
          sizes={sizes}
          alt={alt}
          loading={priority ? 'eager' : 'lazy'}
          decoding="async"
          onError={() => setFailed(true)}
        />
      )}
    </span>
  );
}
