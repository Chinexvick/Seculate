export type LegalDoc = {
  title: string;
  updated: string;
  intro: string;
  sections: { id: string; title: string; body: (string | string[])[] }[];
};

export const legal: Record<'privacy' | 'terms', LegalDoc> = {
  privacy: {
    title: 'Privacy Policy',
    updated: 'September 2026',
    intro:
      'Your privacy matters to us. This policy explains what personal data Seculate collects, why we collect it, how we use and protect it, and the choices and rights you have. We process personal data in line with the Nigeria Data Protection Act 2023 and other applicable laws.',
    sections: [
      {
        id: 'data-we-collect',
        title: 'Information we collect',
        body: [
          'We collect information you give us and information generated when you use Seculate:',
          [
            'Account details: your name, email address, phone number, password and profile photo.',
            'Verification details: information and documents needed to confirm your identity.',
            'Listings and requests: photos, descriptions, prices, availability and location of items or services.',
            'Messages: chats between you and other users inside the app.',
            'Transactions: payment status, amounts, dates and plan subscriptions (card details are handled by our payment providers).',
            'Usage and device data: app interactions, approximate location, device type, IP address and crash reports.',
          ],
        ],
      },
      {
        id: 'how-we-use',
        title: 'How we use your information',
        body: [
          [
            'To create and manage your account and verify your identity.',
            'To show listings near you and connect borrowers, lenders and service providers.',
            'To process payments and plan subscriptions.',
            'To keep the community safe, including preventing fraud and investigating reports.',
            'To provide customer support and respond to your requests.',
            'To improve Seculate, fix problems and develop new features.',
            'To send service messages and, where you agree, news and offers (you can opt out at any time).',
          ],
        ],
      },
      {
        id: 'legal-basis',
        title: 'Our legal basis',
        body: [
          'We process your data to perform our contract with you, to comply with legal obligations, for our legitimate interests in running a safe and useful service, and, where required, with your consent. Where we rely on consent, you can withdraw it at any time.',
        ],
      },
      {
        id: 'sharing',
        title: 'When we share information',
        body: [
          'We do not sell your personal data. We share it only when needed:',
          [
            'With other users: your public profile, ratings, reviews and listings are visible to others, and the people you transact with see the details needed to complete an exchange.',
            'With service providers who help us run Seculate (for example hosting, payments, verification, analytics and customer support) under contracts that protect your data.',
            'With authorities when required by law, or to protect the rights, property or safety of our users and the public.',
            'In a business transfer, such as a merger or acquisition, with appropriate safeguards.',
          ],
        ],
      },
      {
        id: 'retention',
        title: 'How long we keep data',
        body: [
          'We keep personal data only as long as necessary for the purposes in this policy, including to meet legal, accounting and safety requirements. When it is no longer needed, we delete or anonymise it.',
        ],
      },
      {
        id: 'security',
        title: 'How we protect your data',
        body: [
          'We use technical and organisational measures such as encryption in transit, access controls and monitoring to protect your data. No system is perfectly secure, so please use a strong, unique password and never share one-time codes.',
        ],
      },
      {
        id: 'rights',
        title: 'Your rights',
        body: [
          'Subject to the law, you have the right to:',
          [
            'Access the personal data we hold about you.',
            'Correct inaccurate or incomplete data.',
            'Ask us to delete your data.',
            'Object to or restrict certain processing.',
            'Receive your data in a portable format.',
            'Withdraw consent where processing is based on consent.',
            'Lodge a complaint with the Nigeria Data Protection Commission.',
          ],
          'To exercise any of these rights, contact us through the Contact page.',
        ],
      },
      {
        id: 'children',
        title: 'Children',
        body: ['Seculate is not intended for anyone under 18, and we do not knowingly collect data from children.'],
      },
      {
        id: 'changes',
        title: 'Changes to this policy',
        body: [
          'We may update this policy from time to time. If we make significant changes we will let you know in the app or by email. The date at the top shows when it was last updated.',
        ],
      },
      {
        id: 'contact',
        title: 'Contact us',
        body: ['If you have questions about this policy or your data, please reach us through the Contact page.'],
      },
    ],
  },
  terms: {
    title: 'Terms of Service',
    updated: 'September 2026',
    intro:
      'These terms govern your use of the Seculate app and website. By creating an account or using Seculate, you agree to them. Please read them carefully.',
    sections: [
      {
        id: 'about',
        title: 'About Seculate',
        body: [
          'Seculate is a marketplace that connects people and businesses who want to borrow, lend or rent items, and to offer or find local services. Seculate is not a party to the agreements between users, and does not own, inspect or guarantee the items or services listed.',
        ],
      },
      {
        id: 'eligibility',
        title: 'Eligibility and your account',
        body: [
          [
            'You must be at least 18 years old and able to enter into a binding contract.',
            'The information you provide, including for verification, must be accurate and kept up to date.',
            'You are responsible for keeping your login details secure and for all activity on your account.',
            'One person or business per account. Do not create accounts for other people without permission.',
          ],
        ],
      },
      {
        id: 'listings',
        title: 'Listings',
        body: [
          'If you list an item or service, you confirm that you have the right to offer it, that your description and photos are accurate, and that it is safe and legal. You must not list prohibited items, including anything illegal, stolen, dangerous, counterfeit or restricted by law.',
        ],
      },
      {
        id: 'transactions',
        title: 'Borrowing, lending and services',
        body: [
          [
            'Borrowers and lenders agree the price, dates, condition, deposit and return details between themselves, ideally in the in-app chat.',
            'Borrowers must use items with reasonable care and return them on time and in the agreed condition, allowing for normal wear.',
            'Lenders and providers must deliver the item or service as described.',
            'Users are responsible for resolving disputes fairly. Seculate may help mediate but is not obliged to decide outcomes.',
          ],
        ],
      },
      {
        id: 'plans',
        title: 'Plans and payments',
        body: [
          'Seculate offers a free plan and paid monthly plans with different listing limits, durations and visibility. Prices are shown in the app before you subscribe. Paid plans renew monthly until cancelled. Payments are processed by third-party payment providers, and fees already paid are generally non-refundable except where required by law.',
        ],
      },
      {
        id: 'conduct',
        title: 'Acceptable use',
        body: [
          'You agree not to:',
          [
            'Harass, threaten, discriminate against or defraud other users.',
            'Move transactions off Seculate to avoid fees or protections.',
            'Post false, misleading or infringing content, or fake reviews.',
            'Interfere with the app, attempt to access other accounts or scrape data.',
            'Use Seculate for any unlawful purpose.',
          ],
        ],
      },
      {
        id: 'content',
        title: 'Your content',
        body: [
          'You keep ownership of the content you post. You give Seculate a non-exclusive, worldwide, royalty-free licence to host, display and promote it in connection with the service. You are responsible for making sure you have the rights to what you post.',
        ],
      },
      {
        id: 'suspension',
        title: 'Suspension and termination',
        body: [
          'We may remove content, limit features or suspend or close accounts that break these terms or put others at risk. You can close your account at any time by contacting us.',
        ],
      },
      {
        id: 'liability',
        title: 'Disclaimers and liability',
        body: [
          'Seculate is provided “as is”. To the extent permitted by law, we are not responsible for the condition, safety or legality of items and services listed by users, or for the conduct of users, and our total liability to you is limited to the amount you paid us in the three months before the claim. Nothing in these terms limits liability that cannot be limited by law.',
        ],
      },
      {
        id: 'law',
        title: 'Governing law',
        body: ['These terms are governed by the laws of the Federal Republic of Nigeria, and disputes will be handled by the courts of Nigeria.'],
      },
      {
        id: 'changes',
        title: 'Changes to these terms',
        body: [
          'We may update these terms from time to time. If changes are significant we will notify you in the app or by email. Continuing to use Seculate after changes take effect means you accept the updated terms.',
        ],
      },
      {
        id: 'contact',
        title: 'Contact',
        body: ['Questions about these terms? Reach us through the Contact page.'],
      },
    ],
  },
};
