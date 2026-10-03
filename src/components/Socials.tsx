// Add the X profile URL when it is ready; accounts without a link are not shown.
const socials = [
  {
    label: 'Instagram',
    href: 'https://www.instagram.com/seculate_ng',
    icon: (
      <g fill="none" stroke="currentColor" strokeWidth="1.9">
        <rect x="3" y="3" width="18" height="18" rx="5" />
        <circle cx="12" cy="12" r="4.2" />
        <circle cx="17.4" cy="6.6" r="0.6" fill="currentColor" stroke="none" />
      </g>
    ),
  },
  {
    label: 'Facebook',
    href: 'https://www.facebook.com/share/19qCs5uJcK/',
    icon: (
      <path d="M14 22v-9h3l.5-3.6H14V7.2c0-1 .3-1.7 1.8-1.7h1.9V2.3c-.3 0-1.5-.2-2.8-.2-2.8 0-4.6 1.7-4.6 4.8v2.6H7.2V13h3.1v9H14Z" />
    ),
  },
  {
    label: 'TikTok',
    href: 'https://www.tiktok.com/@seculate_ng',
    icon: (
      <path d="M16.6 2h-3.3v13.4c0 1.6-1.3 2.9-2.9 2.9a2.9 2.9 0 0 1-2.9-2.9c0-1.6 1.2-2.9 2.8-2.9.3 0 .6 0 .9.1V9.2c-.3 0-.6-.1-.9-.1-3.5 0-6.3 2.8-6.3 6.3s2.8 6.3 6.3 6.3 6.3-2.8 6.3-6.3V8.6c1.3.9 2.8 1.4 4.4 1.4V6.7c-2.4 0-4.4-2-4.4-4.7Z" />
    ),
  },
  {
    label: 'X',
    href: '',
    icon: (
      <path d="M17.8 3h3l-6.6 7.6L22 21h-6.1l-4.8-6.2L5.6 21H2.6l7.1-8.1L2.2 3h6.2l4.3 5.7L17.8 3Zm-1 16.2h1.7L7.3 4.7H5.5l11.3 14.5Z" />
    ),
  },
];

export function Socials() {
  return (
    <ul className="socials" aria-label="Seculate on social media">
      {socials.filter((s) => s.href).map((s) => (
        <li key={s.label}>
          <a
            href={s.href}
            className="socials__link"
            aria-label={s.label}
            target="_blank"
            rel="noopener noreferrer"
          >
            <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden>
              {s.icon}
            </svg>
          </a>
        </li>
      ))}
    </ul>
  );
}
