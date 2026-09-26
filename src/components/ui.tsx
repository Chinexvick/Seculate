import { useState, type FormEvent, type ReactNode } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { ease, fadeUp, stagger, viewport } from '../lib/motion';
import { Icon, type IconName } from './Icon';

/* Section wrapper with an optional heading ------------------------------------ */
export function Section({
  eyebrow,
  title,
  lead,
  children,
  tone,
  id,
  center,
}: {
  eyebrow?: string;
  title?: ReactNode;
  lead?: ReactNode;
  children?: ReactNode;
  tone?: 'mint' | 'navy';
  id?: string;
  center?: boolean;
}) {
  return (
    <section id={id} className={`psec ${tone ? `psec--${tone}` : ''}`}>
      <div className="psec__inner">
        {(eyebrow || title || lead) && (
          <motion.header
            className={`psec__head ${center ? 'psec__head--center' : ''}`}
            variants={stagger(0.08)}
            initial="hidden"
            whileInView="show"
            viewport={viewport}
          >
            {eyebrow && (
              <motion.p className="eyebrow" variants={fadeUp}>
                {eyebrow}
              </motion.p>
            )}
            {title && (
              <motion.h2 className="psec__title" variants={fadeUp}>
                {title}
              </motion.h2>
            )}
            {lead && (
              <motion.p className="psec__lead" variants={fadeUp}>
                {lead}
              </motion.p>
            )}
          </motion.header>
        )}
        {children}
      </div>
    </section>
  );
}

/* Grid of icon cards ------------------------------------------------------------ */
export type Feature = { icon: IconName; title: string; text: ReactNode };

export function FeatureGrid({ items, cols = 3 }: { items: Feature[]; cols?: 2 | 3 | 4 }) {
  return (
    <motion.ul
      className={`fgrid fgrid--${cols}`}
      variants={stagger(0.08)}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, amount: 0.15 }}
    >
      {items.map((f) => (
        <motion.li key={f.title} className="fcard" variants={fadeUp}>
          <span className="fcard__icon">
            <Icon name={f.icon} />
          </span>
          <h3 className="fcard__title">{f.title}</h3>
          <p className="fcard__text">{f.text}</p>
        </motion.li>
      ))}
    </motion.ul>
  );
}

/* FAQ accordion ----------------------------------------------------------------- */
export type Faq = { q: string; a: ReactNode };

export function FaqList({ items }: { items: Faq[] }) {
  const [open, setOpen] = useState<number | null>(null);
  return (
    <ul className="faq">
      {items.map((f, i) => {
        const isOpen = open === i;
        return (
          <li key={f.q} className={`faq__item ${isOpen ? 'is-open' : ''}`}>
            <button
              type="button"
              className="faq__q"
              aria-expanded={isOpen}
              onClick={() => setOpen(isOpen ? null : i)}
            >
              <span>{f.q}</span>
              <span className="faq__plus" aria-hidden />
            </button>
            <AnimatePresence initial={false}>
              {isOpen && (
                <motion.div
                  className="faq__a"
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.3, ease }}
                >
                  <div className="faq__a-inner">{f.a}</div>
                </motion.div>
              )}
            </AnimatePresence>
          </li>
        );
      })}
    </ul>
  );
}

/* Simple form with a thank-you state ---------------------------------------------- */
export type Field = {
  name: string;
  label: string;
  type?: 'text' | 'email' | 'tel' | 'url' | 'textarea' | 'select';
  placeholder?: string;
  options?: string[];
  required?: boolean;
  /** Take the full row on desktop. */
  full?: boolean;
};

export function LeadForm({
  fields,
  submitLabel,
  successTitle,
  successText,
}: {
  fields: Field[];
  submitLabel: string;
  successTitle: string;
  successText: string;
}) {
  const [sent, setSent] = useState(false);

  // TODO: post the form data to the backend once it exists.
  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSent(true);
  };

  return (
    <div className="lform">
      <AnimatePresence mode="wait" initial={false}>
        {sent ? (
          <motion.div
            key="sent"
            className="lform__sent"
            role="status"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, ease }}
          >
            <span className="lform__tick">
              <Icon name="check" size={26} />
            </span>
            <h3>{successTitle}</h3>
            <p>{successText}</p>
          </motion.div>
        ) : (
          <motion.form key="form" className="lform__grid" onSubmit={onSubmit} exit={{ opacity: 0, y: -10 }}>
            {fields.map((f) => {
              const id = `f-${f.name}`;
              const common = {
                id,
                name: f.name,
                required: f.required ?? true,
                placeholder: f.placeholder,
                className: 'lform__input',
              };
              return (
                <label key={f.name} htmlFor={id} className={`lform__field ${f.full ? 'lform__field--full' : ''}`}>
                  <span className="lform__label">{f.label}</span>
                  {f.type === 'textarea' ? (
                    <textarea {...common} rows={5} />
                  ) : f.type === 'select' ? (
                    <select {...common} defaultValue="">
                      <option value="" disabled>
                        {f.placeholder ?? 'Choose one'}
                      </option>
                      {f.options?.map((o) => (
                        <option key={o}>{o}</option>
                      ))}
                    </select>
                  ) : (
                    <input {...common} type={f.type ?? 'text'} />
                  )}
                </label>
              );
            })}
            <div className="lform__actions">
              <motion.button
                type="submit"
                className="btn btn--green lform__btn"
                whileHover={{ scale: 1.03 }}
                whileTap={{ scale: 0.97 }}
              >
                {submitLabel}
              </motion.button>
            </div>
          </motion.form>
        )}
      </AnimatePresence>
    </div>
  );
}

/* Closing call-to-action band ------------------------------------------------------ */
export function CtaBand({
  title,
  text,
  primary = { label: 'Download the app', to: '/#download' },
  secondary,
}: {
  title: string;
  text: string;
  primary?: { label: string; to: string };
  secondary?: { label: string; to: string };
}) {
  return (
    <section className="psec">
      <div className="psec__inner">
        <motion.div
          className="ctaband"
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={viewport}
          transition={{ duration: 0.7, ease }}
        >
          <div className="ctaband__copy">
            <h2>{title}</h2>
            <p>{text}</p>
          </div>
          <div className="ctaband__actions">
            <Link to={primary.to} className="btn btn--white ctaband__btn">
              {primary.label} <Icon name="arrow" size={16} />
            </Link>
            {secondary && (
              <Link to={secondary.to} className="btn ctaband__btn ctaband__btn--ghost">
                {secondary.label}
              </Link>
            )}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
