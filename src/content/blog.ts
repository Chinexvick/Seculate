import type { PhotoSource } from '../components/Photo';
import { photos } from './photos';

/**
 * Blog content. Kept as structured data (not HTML) so it can be swapped for a CMS / backend
 * later: the API only needs to return posts in this same shape.
 */
export type Block =
  | { type: 'p'; text: string }
  | { type: 'h2'; text: string }
  | { type: 'h3'; text: string }
  | { type: 'ul'; items: string[] }
  | { type: 'ol'; items: string[] }
  | { type: 'quote'; text: string }
  | { type: 'callout'; title: string; text: string };

export type Post = {
  slug: string;
  title: string;
  excerpt: string;
  category: 'Save money' | 'Trust & safety' | 'Earn' | 'Services' | 'Students';
  date: string; // ISO date
  author: string;
  image: PhotoSource;
  body: Block[];
};

export const posts: Post[] = [
  {
    slug: 'the-hidden-cost-of-owning-things-you-rarely-use',
    title: 'The hidden cost of owning things you rarely use',
    excerpt:
      'That drill, projector or pressure washer cost more than the price tag. Here’s why buying everything you need once is quietly draining your money, and what to do instead.',
    category: 'Save money',
    date: '2026-09-22',
    author: 'Seculate Team',
    image: photos.tools,
    body: [
      {
        type: 'p',
        text: 'Think about the last time you bought something for a single job. Maybe a power drill to hang a few shelves. A ring light for one video shoot. A ladder to fix a ceiling fan. A set of chairs for a family event. You needed it, you bought it, you used it once, and then it went into a corner, a cupboard or under the bed, where it has been ever since.',
      },
      {
        type: 'p',
        text: 'Almost every home has a collection like this. On its own each purchase feels reasonable. Added together, they represent a surprising amount of money that is doing absolutely nothing for you. And as prices for almost everything keep climbing, “buy it just in case” has become one of the most expensive habits we have.',
      },
      { type: 'h2', text: 'The price tag is only the beginning' },
      {
        type: 'p',
        text: 'When we decide whether to buy something, we usually compare the price to how badly we need it. But the real cost of owning an item is much bigger than what you pay at the shop. There are at least five costs hiding behind every rarely-used purchase:',
      },
      {
        type: 'ol',
        items: [
          'The upfront cost. The full retail price, paid at once, often for something you need for a few hours.',
          'Depreciation. The moment you open the box, it is worth less. Electronics lose value especially fast, and newer models make yours outdated.',
          'Storage. Space in your home is not free. Every bulky item that sits idle takes up room you pay rent for.',
          'Maintenance. Batteries die, parts rust, cables get lost. Things that sit unused often don’t work when you finally need them again.',
          'Opportunity cost. The money tied up in idle things could have gone to school fees, your business, savings or something that actually improves your life every day.',
        ],
      },
      {
        type: 'callout',
        title: 'A simple way to see it',
        text: 'Divide what you paid for an item by the number of times you have actually used it. A tool that cost ₦60,000 and has been used three times cost you ₦20,000 per use, before you count storage, repairs or the value it has lost.',
      },
      { type: 'h2', text: 'Why we keep buying anyway' },
      {
        type: 'p',
        text: 'If owning rarely-used things is so expensive, why does everyone keep doing it? Mostly because the alternatives have been frustrating. Borrowing from friends only works if a friend happens to own what you need, lives nearby and is available when you need it. Asking around on WhatsApp groups is slow and unreliable. Traditional rental shops often focus on big-ticket items, are far away, or aren’t open when you need them.',
      },
      {
        type: 'p',
        text: 'There is also a trust problem. Lending your camera to a stranger feels risky. Borrowing a generator from someone you have never met feels uncertain. Without a way to know who you are dealing with, buying your own feels like the “safe” option, even when it is the expensive one.',
      },
      { type: 'h2', text: 'Access beats ownership' },
      {
        type: 'p',
        text: 'Here is the shift that changes everything: for most things, you don’t actually want to own them. You want what they do. You don’t want a drill, you want holes in the wall. You don’t want a projector, you want a great movie night or a clear presentation. You don’t want a pressure washer, you want a clean compound.',
      },
      {
        type: 'p',
        text: 'Once you think about it that way, the question changes from “should I buy this?” to “what is the easiest and cheapest way to get this done?” And very often, the answer is to borrow or rent it from someone nearby who already owns one and isn’t using it today.',
      },
      {
        type: 'quote',
        text: 'The cheapest item you will ever own is the one you never had to buy.',
      },
      { type: 'h2', text: 'When buying still makes sense' },
      {
        type: 'p',
        text: 'This doesn’t mean you should never buy anything. Some things are worth owning. A quick checklist before you buy:',
      },
      {
        type: 'ul',
        items: [
          'Will I use it at least weekly? Daily-use items like your phone or kitchen basics are worth owning.',
          'Is it personal or hygienic? Some things, like undergarments or certain personal care items, are better owned.',
          'Do I need it instantly and unpredictably? Emergency items such as a first-aid kit belong at home.',
          'Will it hold its value? If you will use it often and it keeps its value, buying can be a good investment.',
        ],
      },
      {
        type: 'p',
        text: 'If the answer to all of these is no, borrowing or renting is almost certainly the smarter move.',
      },
      { type: 'h2', text: 'Turn the problem into income' },
      {
        type: 'p',
        text: 'There is a second half to this story. The items already sitting idle in your home are not just a sunk cost. They are an opportunity. The same camera, speaker, tool set or party equipment you rarely use is exactly what someone a few streets away is looking for this weekend.',
      },
      {
        type: 'p',
        text: 'By lending them out, you turn dead money back into living money. A few rentals a month can cover the original cost of an item, pay for its maintenance, or simply add a welcome boost to your income.',
      },
      { type: 'h2', text: 'How Seculate helps' },
      {
        type: 'p',
        text: 'Seculate was built for exactly this. It connects you with verified people and businesses nearby so you can borrow what you need for as long as you need it, and lend what you don’t use. Ratings, reviews, in-app chat and secure payments take the guesswork out of dealing with people you haven’t met before.',
      },
      {
        type: 'ul',
        items: [
          'Need something for a day or a weekend? Search nearby, chat with the owner, and pick it up.',
          'Have things gathering dust? List up to 3 items a month for free on the On Code plan and start earning.',
          'Lending often? Upgrade to a plan with more listings and better visibility when you are ready.',
        ],
      },
      {
        type: 'p',
        text: 'The next time you are about to buy something you will only use once, pause and check Seculate first. Your wallet, and your cupboard, will thank you.',
      },
    ],
  },
  {
    slug: 'borrowing-from-strangers-feels-risky-heres-how-trust-fixes-it',
    title: 'Borrowing from strangers feels risky. Here’s how trust fixes it.',
    excerpt:
      'Scams, no-shows and damaged items have made many of us wary of dealing with people we don’t know. Here’s what real trust looks like, and how to build it into every exchange.',
    category: 'Trust & safety',
    date: '2026-09-15',
    author: 'Seculate Team',
    image: photos.handshake,
    body: [
      {
        type: 'p',
        text: 'Most of us have a story. A friend paid for something online that never arrived. A neighbour lent out a generator and got it back broken, with no apology. Someone in a WhatsApp group took a deposit and disappeared. Stories like these travel fast, and they leave all of us a little more careful, and a little less willing to share.',
      },
      {
        type: 'p',
        text: 'That caution is understandable. But it comes at a price. When we don’t trust each other, we end up buying things we barely use, paying more for services because we only go with “who we know”, and missing out on the income and convenience that sharing could bring. Low trust is expensive.',
      },
      { type: 'h2', text: 'Why informal sharing breaks down' },
      {
        type: 'p',
        text: 'Borrowing and lending are not new. Families, friends and neighbours have always shared. What has changed is scale. Informal sharing works well inside a small circle where everyone knows everyone and reputations follow people around. It starts to break down when you need something from outside that circle.',
      },
      {
        type: 'ul',
        items: [
          'No identity. In a group chat you often have no real way to confirm who someone is.',
          'No history. You can’t see how that person has treated others in the past.',
          'No clear agreement. Prices, dates and conditions get lost in voice notes and long threads.',
          'No safe payment. Sending money to a stranger’s account means you have no protection if things go wrong.',
          'No accountability. If something is damaged or never returned, there is nobody to turn to.',
        ],
      },
      {
        type: 'p',
        text: 'Each of these gaps is a door for bad actors, and a reason for honest people to stay away. Fix them, and sharing between strangers becomes not just possible, but easy.',
      },
      { type: 'h2', text: 'The five building blocks of trust' },
      {
        type: 'p',
        text: 'Trust between strangers isn’t magic. It is built from a few simple ingredients, and when they are all present, people behave remarkably well.',
      },
      { type: 'h3', text: '1. Knowing who you are dealing with' },
      {
        type: 'p',
        text: 'Verification is the foundation. When people know that the person on the other side has confirmed their identity, anonymous scams become much harder, and everyone behaves as though their name is attached to their actions, because it is.',
      },
      { type: 'h3', text: '2. A track record you can see' },
      {
        type: 'p',
        text: 'Ratings and reviews turn every exchange into a public reputation. A lender with dozens of positive reviews has earned your confidence. A new user can build theirs one good exchange at a time. And the knowledge that you will be reviewed is a powerful reason to be on time, honest and careful.',
      },
      { type: 'h3', text: '3. Clear, written agreements' },
      {
        type: 'p',
        text: 'Most disputes aren’t caused by bad people. They are caused by misunderstandings. Agreeing the price, dates, condition, deposit and return details in writing, before anything changes hands, removes almost all of the “but I thought…” moments.',
      },
      { type: 'h3', text: '4. Payments that protect both sides' },
      {
        type: 'p',
        text: 'Paying through a secure platform instead of transferring to a stranger’s personal account protects the borrower from paying for something that never arrives, and gives the lender confidence that payment is real.',
      },
      { type: 'h3', text: '5. Someone to turn to' },
      {
        type: 'p',
        text: 'Finally, trust needs a safety net. Knowing that you can report a problem, and that there is a team who will look into it, changes how comfortable people feel taking part in the first place.',
      },
      {
        type: 'quote',
        text: 'Trust is not about believing everyone is good. It is about building a system where being good is the easiest option.',
      },
      { type: 'h2', text: 'What you can do on every exchange' },
      {
        type: 'p',
        text: 'Whichever side of an exchange you are on, a few habits dramatically reduce your risk:',
      },
      {
        type: 'ul',
        items: [
          'Check the profile: verification, ratings and what other people have said.',
          'Keep all communication in one place so there is a record of what was agreed.',
          'Never pay outside the platform, no matter how convincing the reason.',
          'Inspect items at handover and take photos. Share them in the chat.',
          'Meet in public places where possible, and tell someone where you are going.',
          'If something feels off, it is fine to walk away. There will be other listings.',
        ],
      },
      {
        type: 'callout',
        title: 'The biggest red flag',
        text: 'Anyone pushing you to move the conversation or payment to another app, “to make it faster” or “to avoid fees”, is removing your protection. Treat it as a warning sign.',
      },
      { type: 'h2', text: 'How Seculate is designed for trust' },
      {
        type: 'p',
        text: 'Every part of Seculate is built around those five building blocks. Users are verified. Every completed exchange can be rated and reviewed. Conversations happen in in-app chat, so agreements are clear and recorded. Payments are handled securely. And if something goes wrong, you can report it directly to our team.',
      },
      {
        type: 'p',
        text: 'The result is a place where you can borrow a camera from someone across town, or rent your speaker to a student hosting an event, with the same confidence you would have lending to a close friend.',
      },
      {
        type: 'p',
        text: 'Sharing only works when it feels safe. We’re building Seculate so that it does. Read our full Safety guide for more practical tips, and help us build a community where trust is the norm, not the exception.',
      },
    ],
  },
  {
    slug: 'turn-idle-items-into-income',
    title: 'Your idle stuff could be earning for you: a practical guide to lending',
    excerpt:
      'Cameras, tools, speakers, party gear: the things you rarely use are exactly what someone nearby needs this weekend. Here’s how to turn them into steady extra income, safely.',
    category: 'Earn',
    date: '2026-09-08',
    author: 'Seculate Team',
    image: photos.camera,
    body: [
      {
        type: 'p',
        text: 'Almost everyone is looking for ways to make their money go further right now. Side hustles have become the norm, but many of them need a lot of time, upfront capital or skills you don’t have yet. There is one income source most people overlook completely, and it is already sitting in your home.',
      },
      {
        type: 'p',
        text: 'The camera you bought for a project. The drill you used twice. The speaker that only comes out for birthdays. The canopy and chairs from the family event. Each of these is an asset. Right now they are depreciating quietly. Listed on Seculate, they can start paying you back.',
      },
      { type: 'h2', text: 'Step 1: Do a quick “idle audit”' },
      {
        type: 'p',
        text: 'Walk through your home with fresh eyes and make a list of anything you have used fewer than once a month in the past year. Don’t judge yet, just write it down. Most people are surprised by how long the list gets.',
      },
      {
        type: 'p',
        text: 'Items that tend to be in demand include:',
      },
      {
        type: 'ul',
        items: [
          'Electronics and appliances: cameras, lenses, projectors, speakers, gaming consoles, laptops, generators.',
          'Tools and utility gear: drills, ladders, pressure washers, lawn mowers, toolkits, extension cables.',
          'Event and party equipment: canopies, chairs, tables, coolers, lighting, sound systems.',
          'Sports and outdoor gear: bicycles, camping equipment, fitness equipment.',
          'Fashion: occasion wear, traditional attire, designer bags and accessories for special events.',
        ],
      },
      { type: 'h2', text: 'Step 2: Decide what you are comfortable lending' },
      {
        type: 'p',
        text: 'Not everything on your list needs to be listed. Ask yourself two questions for each item. Would I be okay if it came back with normal wear? And can I live without it for a few days at a time? If the answer to both is yes, it is a great candidate. Start with items that are sturdy, easy to check and simple to explain.',
      },
      { type: 'h2', text: 'Step 3: Price it smartly' },
      {
        type: 'p',
        text: 'Pricing is where most first-time lenders either leave money on the table or scare borrowers away. A few principles help:',
      },
      {
        type: 'ul',
        items: [
          'Look at similar listings near you to understand what people are already paying.',
          'Consider the item’s value and demand. High-value, high-demand items can command more.',
          'Offer a better rate for longer rentals. A weekly price that is less than seven daily prices encourages bigger bookings.',
          'Start slightly lower to win your first reviews, then adjust as your reputation grows.',
        ],
      },
      {
        type: 'callout',
        title: 'Think in “uses to pay off”',
        text: 'If an item cost you ₦80,000 and you rent it for ₦8,000 a day, ten rental days pays for it completely. Everything after that is profit, while you still own the item.',
      },
      { type: 'h2', text: 'Step 4: Create a listing people trust' },
      {
        type: 'p',
        text: 'Borrowers are deciding whether to trust you with their time and money. Your listing is your shop window, so make it count:',
      },
      {
        type: 'ol',
        items: [
          'Photos: use natural light and a clean background, and show the item from several angles, including any wear.',
          'Title: be specific. “Canon DSLR with 18–55mm lens and charger” beats “Camera for rent”.',
          'Description: explain what is included, the condition, how it works and any rules (for example, no use in rain).',
          'Availability: keep your calendar up to date so people can book with confidence.',
          'Profile: add a clear photo and complete verification. People rent from people they trust.',
        ],
      },
      { type: 'h2', text: 'Step 5: Protect your items' },
      {
        type: 'p',
        text: 'Lending is safest when both sides are clear from the start. Before every handover:',
      },
      {
        type: 'ul',
        items: [
          'Check the borrower’s profile, verification and reviews before accepting.',
          'Agree the price, dates, deposit (if any) and condition in the in-app chat.',
          'Take photos or a short video of the item at handover and share them in the chat.',
          'Only use in-app payments, and never hand over items for “payment later” arrangements outside the app.',
        ],
      },
      { type: 'h2', text: 'Step 6: Choose a plan that grows with you' },
      {
        type: 'p',
        text: 'You can start lending on Seculate for free. The On Code plan lets you list up to 3 items a month. As you grow, the paid plans unlock more:',
      },
      {
        type: 'ul',
        items: [
          'Active (₦500/month): up to 5 items a month, with listings live for 30 days.',
          'Hustler (₦1,500/month): up to 10 items, 60-day listings, and your listings featured once a week.',
          'Top Lender (₦5,000/month): unlimited items and duration, top-priority visibility, access to private requests, custom offers and priority support.',
        ],
      },
      {
        type: 'p',
        text: 'A good rule of thumb: upgrade when your plan’s limits start to hold you back. If you consistently have more items to list, or want more people to see them, it is time.',
      },
      {
        type: 'quote',
        text: 'You don’t need to buy anything new to start earning. You just need to look at what you already own a little differently.',
      },
      { type: 'h2', text: 'Your first-week checklist' },
      {
        type: 'ol',
        items: [
          'Download Seculate and complete your profile and verification.',
          'List your three most in-demand idle items with great photos.',
          'Reply to every message quickly. Fast responses win bookings.',
          'Deliver a great first experience and ask for a review.',
          'Adjust your prices and descriptions based on the questions people ask.',
        ],
      },
      {
        type: 'p',
        text: 'Every item you lend is money back in your pocket and one less thing someone else has to buy. That is a side hustle that is good for you and for your community.',
      },
    ],
  },
  {
    slug: 'why-finding-a-reliable-technician-is-so-hard',
    title: 'Why finding a reliable technician is so hard, and how to fix it',
    excerpt:
      'Endless referrals, no-shows, surprise prices and jobs done twice. Here’s why hiring local help is so stressful, and a better way to find people you can count on.',
    category: 'Services',
    date: '2026-09-01',
    author: 'Seculate Team',
    image: photos.technician,
    body: [
      {
        type: 'p',
        text: 'Your fridge stops cooling. The AC starts leaking. A socket sparks. What happens next is familiar to almost everyone: you ask your family group chat if anyone knows “a good electrician”. Someone forwards a number. That person doesn’t pick up. Another number arrives. This one promises to come “by 2pm”, shows up at 6, quotes a price, then changes it halfway through the job.',
      },
      {
        type: 'p',
        text: 'Finding reliable help for everyday jobs is one of the most frustrating parts of modern life. And it isn’t because there aren’t skilled people out there. There are many talented technicians, cleaners, tailors, mechanics and artisans. The problem is that it is very hard to find them, and even harder to know in advance who you can count on.',
      },
      { type: 'h2', text: 'The real problems with finding local help' },
      { type: 'h3', text: 'Referral chains are slow and fragile' },
      {
        type: 'p',
        text: 'Word of mouth is still how most people find help. It works when your cousin’s plumber happens to be available. But you are relying on a chain of people remembering numbers, those numbers still being valid, and the person having time when you need them. When you have an urgent problem, that chain is painfully slow.',
      },
      { type: 'h3', text: 'There is no way to compare' },
      {
        type: 'p',
        text: 'With one recommended name, you have no idea whether their price is fair or their work is good compared with others nearby. You take what you get.',
      },
      { type: 'h3', text: 'Prices are unclear' },
      {
        type: 'p',
        text: 'Quotes often change once work begins, “new parts” appear, and there is no written record of what was agreed. Many people end up paying more than expected simply because it is awkward to argue once the job is half done.',
      },
      { type: 'h3', text: 'Nobody is accountable' },
      {
        type: 'p',
        text: 'If a job is done badly, there is rarely any consequence. The provider moves on to the next client and you pay someone else to fix it again. Great providers suffer too, because their excellent work isn’t visible to anyone outside their circle.',
      },
      {
        type: 'callout',
        title: 'It’s a problem for providers too',
        text: 'Skilled professionals lose income every day because customers can’t find them, or don’t trust them yet. A visible reputation helps good providers win more work at fair prices.',
      },
      { type: 'h2', text: 'What “reliable” actually looks like' },
      {
        type: 'p',
        text: 'Before you hire anyone, it helps to know what you are looking for. A reliable provider:',
      },
      {
        type: 'ul',
        items: [
          'Responds clearly and quickly, and gives you a realistic time they can come.',
          'Explains the problem and gives a clear price before starting work.',
          'Asks before doing anything extra, and explains why it is needed.',
          'Shows up when they said they would, or lets you know early if something changes.',
          'Stands by their work and has a track record of happy customers.',
        ],
      },
      { type: 'h2', text: 'How to vet a provider in five minutes' },
      {
        type: 'ol',
        items: [
          'Check their profile for verification, photos of past work and a clear description of what they do.',
          'Read the reviews, especially recent ones and any that mention jobs similar to yours.',
          'Describe your problem in detail in the chat and ask for an estimate and time window.',
          'Confirm the agreed price and scope in writing before work begins.',
          'After the job, test the fix before paying and leave an honest review.',
        ],
      },
      {
        type: 'quote',
        text: 'The best time to agree on price and scope is before the toolbox opens.',
      },
      { type: 'h2', text: 'A better way to find help nearby' },
      {
        type: 'p',
        text: 'Seculate brings local service providers and the people who need them into one trusted place. Instead of waiting for referrals, you can search for the service you need, see who is available nearby, compare profiles, and read what other customers have said.',
      },
      {
        type: 'ul',
        items: [
          'Verified providers, so you know who is coming to your home or business.',
          'Ratings and reviews from real customers, so great work gets noticed.',
          'In-app chat, so the price, scope and timing are clear and recorded.',
          'Secure payments, so both sides are protected.',
        ],
      },
      { type: 'h2', text: 'If you are a service provider' },
      {
        type: 'p',
        text: 'If you are a skilled technician, cleaner, stylist, tailor, mechanic or any other professional, your reputation is your biggest asset. On Seculate, every happy customer can leave a review that helps the next customer choose you. List your services, keep your profile complete, respond quickly and deliver great work, and let your ratings do the marketing for you.',
      },
      {
        type: 'p',
        text: 'Finding good help shouldn’t depend on who you know. With the right information in front of you, it can be as simple as searching, chatting and booking.',
      },
    ],
  },
  {
    slug: 'student-guide-get-what-you-need-without-the-price-tag',
    title: 'A student’s guide to getting what you need without the price tag',
    excerpt:
      'Projects, practicals, events and moving hostels all come with costs. Here’s how smart students borrow instead of buy, and even earn from what they already own.',
    category: 'Students',
    date: '2026-08-25',
    author: 'Seculate Team',
    image: photos.students,
    body: [
      {
        type: 'p',
        text: 'Student life is full of one-off expenses that nobody warns you about. A final-year project that needs a better laptop or camera. A practical that requires special equipment. A departmental dinner that calls for an outfit you will wear once. A move to a new hostel that needs a van, a toolbox and extra hands. Each one is a small emergency for a tight budget.',
      },
      {
        type: 'p',
        text: 'Most students handle these moments the same way: borrow from a friend if you are lucky, spend money you don’t have if you are not. There is a smarter middle ground.',
      },
      { type: 'h2', text: 'The “borrow first” mindset' },
      {
        type: 'p',
        text: 'Before you buy anything for school, ask one question: will I still use this regularly in six months? If the honest answer is no, borrowing or renting is almost always the better choice. It keeps your money free for the things that really matter, like fees, food, transport and data.',
      },
      {
        type: 'p',
        text: 'Things students commonly need for a short time:',
      },
      {
        type: 'ul',
        items: [
          'Laptops, tablets and scientific calculators for exams, projects or when your own device fails.',
          'Cameras, microphones, ring lights and tripods for media projects, content and events.',
          'Projectors and speakers for presentations, fellowship programmes and hangouts.',
          'Outfits and accessories for dinners, weddings, matriculation and convocation.',
          'Tools, trolleys and transport help when moving in or out of hostels.',
        ],
      },
      { type: 'h2', text: 'How to borrow smart' },
      {
        type: 'ol',
        items: [
          'Plan ahead. Popular items get booked quickly around exam periods and events.',
          'Compare a few options nearby before you choose, and read the reviews.',
          'Agree dates, price and condition in the chat, and ask questions if anything is unclear.',
          'Inspect the item when you collect it and share photos in the chat.',
          'Return it on time and in good condition. Your reviews follow you, and a strong profile makes future borrowing easier.',
        ],
      },
      {
        type: 'callout',
        title: 'Split it with your group',
        text: 'Working on a group project? Rent one set of equipment and split the cost between everyone. It’s often cheaper per person than a single textbook.',
      },
      { type: 'h2', text: 'Turn your own stuff into pocket money' },
      {
        type: 'p',
        text: 'Here’s the part many students miss: you probably own things other students need. The camera you bought for a project. The speaker you use once a month. The dress or agbada from an event. The printer in your room. Listed on Seculate, these can earn you steady pocket money without taking time away from your studies.',
      },
      {
        type: 'p',
        text: 'You can start for free. The On Code plan lets you list up to 3 items a month at no cost, which is perfect for testing the waters. If demand is strong, the Active plan (₦500/month) lets you list up to 5 items.',
      },
      { type: 'h2', text: 'Stay safe on and around campus' },
      {
        type: 'ul',
        items: [
          'Meet in busy, public places on campus, like the library entrance or faculty buildings, during the day.',
          'Check profiles, verification and reviews before you agree anything.',
          'Keep all chats and payments in the app, and never share one-time codes or passwords.',
          'Tell a friend where you are going when you meet someone new.',
        ],
      },
      {
        type: 'quote',
        text: 'The smartest students don’t own everything. They know where to get anything.',
      },
      { type: 'h2', text: 'Make your campus a sharing campus' },
      {
        type: 'p',
        text: 'Imagine if every student on your campus could access the laptops, cameras, tools and outfits already owned by the students around them. Fewer people would miss deadlines because of broken devices. Fewer would overspend on things they will use once. More would earn a little extra from what they already have.',
      },
      {
        type: 'p',
        text: 'That is what Seculate makes possible. Download the app, see what is available near your campus, and start saving and earning today. If you run a student association or campus group, get in touch through our Partners page. We would love to work with you.',
      },
    ],
  },
];

export const findPost = (slug: string) => posts.find((p) => p.slug === slug);

/** Rough reading time based on ~220 words per minute. */
export function readingTime(post: Post) {
  const words = post.body
    .map((b) => ('text' in b ? b.text : 'items' in b ? b.items.join(' ') : '') + ('title' in b ? ` ${b.title}` : ''))
    .join(' ')
    .split(/\s+/).length;
  return Math.max(1, Math.round(words / 220));
}

export const formatDate = (iso: string) =>
  new Date(`${iso}T12:00:00`).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
