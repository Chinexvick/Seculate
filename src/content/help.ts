import type { IconName } from '../components/Icon';

export type HelpTopic = {
  id: string;
  icon: IconName;
  title: string;
  blurb: string;
  faqs: { q: string; a: string }[];
};

export const helpTopics: HelpTopic[] = [
  {
    id: 'getting-started',
    icon: 'spark',
    title: 'Getting started',
    blurb: 'Create your account and find your way around.',
    faqs: [
      {
        q: 'What is Seculate?',
        a: 'Seculate is a marketplace that connects you with people and businesses nearby so you can borrow, lend and rent everyday items, and find trusted local services, all in one place. Instead of buying something you only need once, you can borrow it from someone close by. And the things you own but rarely use can earn you money.',
      },
      {
        q: 'How do I get started?',
        a: 'Download the Seculate app, create your account and complete verification. From there you can browse categories, search for what you need, or list your first item. Everyone starts on the free On Code plan, so you can explore without paying anything.',
      },
      {
        q: 'What can I find on Seculate?',
        a: 'Electronics and appliances, vehicles, sports gear, cleaning and utility equipment, media and gadgets, fashion, home and living items, and a growing list of local services. If people nearby own it or offer it, you can find it on Seculate.',
      },
      {
        q: 'Do I need to pay to join?',
        a: 'No. Creating an account and browsing is free, and the On Code plan lets you list up to 3 items a month at no cost. You only pay if you choose to upgrade to a paid plan for more listings and better visibility.',
      },
    ],
  },
  {
    id: 'borrowing',
    icon: 'search',
    title: 'Borrowing & renting',
    blurb: 'Find what you need and get it safely.',
    faqs: [
      {
        q: 'How do I find an item or service?',
        a: 'Use search or browse by category to see listings near you. Each listing shows photos, the price, the provider’s rating and details about condition and availability. Open a listing to read everything before you reach out.',
      },
      {
        q: 'How do I request something?',
        a: 'Tap the listing, chat with the provider to confirm the details (dates, price, pickup or delivery, and condition), then confirm your request in the app. Keeping the whole conversation in Seculate chat means there is a clear record of what was agreed.',
      },
      {
        q: 'What should I check when I pick up an item?',
        a: 'Inspect it in front of the lender. Make sure it matches the photos and description, test that it works, and take a few photos or a short video. Share them in the chat before you leave so both of you agree on its condition at handover.',
      },
      {
        q: 'How do returns work?',
        a: 'Return the item on the date and in the condition you agreed in the chat. If you need more time, ask the lender before the return date. Most lenders are happy to extend when you ask early. After the return, both of you can leave a rating and review.',
      },
      {
        q: 'What if something breaks while I have it?',
        a: 'Tell the lender straight away through the chat and explain what happened. Be honest and share photos. Most issues are resolved quickly between both parties. If you cannot agree on a fair outcome, contact Seculate support from the app or the Contact page and we will help.',
      },
    ],
  },
  {
    id: 'lending',
    icon: 'box',
    title: 'Listing & lending',
    blurb: 'Turn the things you own into income.',
    faqs: [
      {
        q: 'How do I list an item?',
        a: 'In the app, tap to create a listing, add clear photos from a few angles, write an honest description (including any wear or faults), set your price and availability, and publish. Good photos and a detailed description get more requests.',
      },
      {
        q: 'How many items can I list?',
        a: 'It depends on your plan. On Code (free) lets you list up to 3 items a month, Active up to 5, Hustler up to 10, and Top Lender has no limit. You can upgrade at any time from the Pricing Plans screen in the app.',
      },
      {
        q: 'How long does my listing stay live?',
        a: 'Listing duration also depends on your plan: 2 weeks on On Code, 30 days on Active, 60 days on Hustler and unlimited on Top Lender. You can relist an item when it expires.',
      },
      {
        q: 'How should I price my item?',
        a: 'Look at similar listings nearby and think about the item’s value, its condition and how in-demand it is. A useful starting point for many items is a small fraction of the replacement cost per day, with a discount for longer rentals. You can change your price at any time.',
      },
      {
        q: 'Who can I lend to?',
        a: 'You are always in control. Before you accept a request, check the borrower’s profile, verification and reviews, and ask any questions in the chat. You never have to accept a request that does not feel right.',
      },
    ],
  },
  {
    id: 'plans',
    icon: 'card',
    title: 'Plans & billing',
    blurb: 'Pick the plan that fits how you use Seculate.',
    faqs: [
      {
        q: 'What plans are available?',
        a: 'On Code is free (up to 3 items a month, 2-week listings, standard visibility). Active is ₦500/month (up to 5 items, 30-day listings). Hustler is ₦1,500/month (up to 10 items, 60-day listings, and your listings are featured once a week). Top Lender is ₦5,000/month (unlimited items and duration, top-priority visibility, access to private requests, custom offers and priority support).',
      },
      {
        q: 'What does "visibility" mean?',
        a: 'Visibility is how prominently your listings appear in search and browse. Standard visibility is included on every plan. Hustler listings are also featured once a week, and Top Lender listings get top priority placement.',
      },
      {
        q: 'How do I upgrade my plan?',
        a: 'Open the Pricing Plans screen in the app, choose the plan you want and tap Upgrade. Your new limits apply as soon as the upgrade is confirmed.',
      },
      {
        q: 'What are private requests and custom offers?',
        a: 'They are Top Lender features. Private requests let you see and respond to requests people post for items they cannot find in the listings. Custom offers let you send a tailored price or package to a specific borrower.',
      },
      {
        q: 'I have a question about a charge.',
        a: 'Contact us from the Contact page and choose “Billing” as the topic. Include the email on your account and the date of the charge so we can look into it quickly.',
      },
    ],
  },
  {
    id: 'safety',
    icon: 'shieldCheck',
    title: 'Safety & trust',
    blurb: 'How we help keep every exchange safe.',
    faqs: [
      {
        q: 'How does Seculate keep users safe?',
        a: 'Users are verified, and every completed exchange can be rated and reviewed, so you can see who you are dealing with before you agree to anything. Payments are handled securely, and in-app chat keeps a record of every agreement. Read our Safety page for practical tips.',
      },
      {
        q: 'Should I pay or chat outside the app?',
        a: 'We strongly recommend keeping chats and payments inside Seculate. Moving to other apps removes the record of your agreement and makes it much harder for us to help if something goes wrong. Be cautious of anyone who pushes you to pay outside the app.',
      },
      {
        q: 'How do I report a user or listing?',
        a: 'Use the report option on the user’s profile or the listing in the app, or contact us from the Contact page and choose “Report a safety concern”. If you are ever in immediate danger, contact local emergency services first.',
      },
    ],
  },
  {
    id: 'account',
    icon: 'lock',
    title: 'Account & privacy',
    blurb: 'Manage your profile, data and security.',
    faqs: [
      {
        q: 'How do I update my profile?',
        a: 'Go to your profile in the app to update your photo, name, location and contact details. A complete profile with a clear photo helps others trust you.',
      },
      {
        q: 'How do I keep my account secure?',
        a: 'Use a strong password that you do not use anywhere else, never share one-time codes with anyone (Seculate will never ask for them), and log out of shared devices.',
      },
      {
        q: 'How do I delete my account?',
        a: 'Contact us from the Contact page with the email on your account and we will process your request. Our Privacy Policy explains what happens to your data when an account is deleted.',
      },
    ],
  },
];
