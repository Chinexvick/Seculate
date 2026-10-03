import { Photo } from './Photo';
import { itemRows, type Item } from '../content/items';

/**
 * Two endless rows of item cards drifting in opposite directions.
 * Each row renders its cards twice and slides by exactly one set (-50%) with a
 * linear CSS animation, so the loop is seamless and runs on the GPU.
 */
export function ItemMarquee() {
  return (
    <section className="marquee" aria-label="Things you can borrow and lend on Seculate">
      {itemRows.map((row, i) => (
        <div key={i} className={`marquee__row ${i % 2 ? 'marquee__row--reverse' : ''}`}>
          <ul className="marquee__track">
            {[...row, ...row].map((item, j) => (
              <ItemCard key={`${item.name}-${j}`} item={item} hidden={j >= row.length} />
            ))}
          </ul>
        </div>
      ))}
    </section>
  );
}

function ItemCard({ item, hidden }: { item: Item; hidden: boolean }) {
  return (
    <li className={`icard ${item.cutout ? 'icard--cutout' : ''}`} aria-hidden={hidden || undefined}>
      <Photo {...item.photo} className="icard__photo" sizes="135px" maxWidth={320} />
      <span className="icard__label">{item.name}</span>
    </li>
  );
}
