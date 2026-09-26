import type { PhotoSource } from '../components/Photo';

/** Stock photos (Pexels licence: free for commercial use, no attribution required). */
export const photos = {
  lagosTeam: { pexels: 30689114, alt: 'A team collaborating around a laptop in a Lagos office', credit: 'Ninthgrid / Pexels' },
  meeting: { pexels: 9301291, alt: 'Colleagues discussing ideas in a bright meeting room', credit: 'Mikhail Nilov / Pexels' },
  shopOwner: { pexels: 3752747, alt: 'A smiling business owner leaning on her shop counter', credit: 'Andrea Piacquadio / Pexels' },
  friends: { pexels: 1429881, alt: 'A group of friends smiling together outdoors', credit: 'Desmond Gatimu / Pexels' },
  tools: { pexels: 5691653, alt: 'Household tools laid out for a repair job at home', credit: 'Pexels' },
  handshake: { pexels: 955388, alt: 'Two women shaking hands across a table', credit: 'Cytonn Photography / Pexels' },
  camera: { pexels: 5049926, alt: 'A young man holding a camera', credit: 'Lord Keli / Pexels' },
  technician: { pexels: 442154, alt: 'A technician working carefully with his hands', credit: 'Pexels' },
  students: { pexels: 6147009, alt: 'Students working together on a laptop outdoors', credit: 'Keira Burton / Pexels' },
} satisfies Record<string, PhotoSource>;
