import type { PhotoSource } from '../components/Photo';

/** `cutout` = product shot on a white background, shown whole instead of cropped. */
export type Item = { name: string; photo: PhotoSource; cutout?: boolean };

const px = (pexels: number, alt: string): PhotoSource => ({ pexels, alt });
const local = (file: string, alt: string): PhotoSource => ({ src: `/assets/items/${file}.webp`, alt });

/** Things people borrow and lend on Seculate, shown in the two scrolling rows on the home page. */
export const itemRows: Item[][] = [
  [
    { name: 'Laptop', photo: local('laptop', 'A laptop'), cutout: true },
    { name: 'PlayStation 5', photo: px(32713615, 'A PlayStation 5 controller resting on the console') },
    { name: 'Game pad', photo: px(9409822, 'A white game controller on a table') },
    { name: 'Smartphone', photo: px(8533741, 'A smartphone lying on a white surface') },
    { name: 'E-bike', photo: local('e-bike', 'A folding electric bike with fat tyres'), cutout: true },
    { name: 'Generator', photo: local('generator', 'A petrol generator'), cutout: true },
    { name: 'Smart TV', photo: px(1444416, 'A smart TV in a modern living room') },
    { name: 'Standing fan', photo: px(11493642, 'Close-up of an electric fan') },
    { name: 'Earbuds', photo: px(7417547, 'Wireless earbuds with their charging case') },
    { name: 'Camera', photo: px(13491657, 'A DSLR camera with a lens') },
    { name: 'Pressing iron', photo: local('iron', 'A travel pressing iron'), cutout: true },
  ],
  [
    { name: 'Circular saw', photo: local('circular-saw', 'An electric circular saw'), cutout: true },
    { name: 'Hand saw', photo: local('hand-saw', 'A pruning hand saw'), cutout: true },
    { name: 'Shovel', photo: px(296232, 'A shovel') },
    { name: 'Wheelchair', photo: px(927690, 'A wheelchair in a bright room') },
    { name: 'Crutches', photo: px(3846157, 'A pair of crutches against a white wall') },
    { name: 'Charger', photo: px(4097206, 'A phone charger adapter') },
    { name: 'Handbag', photo: px(2977304, 'A brown leather handbag') },
    { name: 'Speaker', photo: px(6023354, 'A portable Bluetooth speaker on a wooden table') },
    { name: 'Power drill', photo: px(3877525, 'A yellow and black cordless drill') },
    { name: 'Guitar', photo: px(13095270, 'An acoustic guitar leaning against a wall') },
    { name: 'Camping tent', photo: px(14287, 'A camping tent in the mountains') },
  ],
];
