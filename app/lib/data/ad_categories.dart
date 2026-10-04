/// Categories used when posting an ad (Figma "Categories" picker).
class AdCategory {
  const AdCategory(this.label, this.image,
      [this.subs = const [], this.subImages = const {}]);
  final String label;
  final String image;
  final List<String> subs;

  /// Optional per-sub-category thumbnails (falls back to [image]).
  final Map<String, String> subImages;

  bool get isService => label == 'Services';
}

const _c = 'assets/images/categories/';
const _s = 'assets/images/services/';

const adCategories = <AdCategory>[
  AdCategory('Electronics & Appliances', '${_c}cat_electronics.png', [
    'TV',
    'Bluetooth Speakers',
    'Standing Fan',
    'Pressing Iron',
    'Blender',
    'Microwave',
    'Home Theater System',
  ]),
  AdCategory('Kitchenware', '${_c}cat_kitchen.png',
      ['Electric Kettle', 'Cooking Pots', 'Gas Cooker', 'Food Warmers']),
  AdCategory('Fashion & Style', '${_c}cat_fashion.png',
      ['Dresses', 'Suits', 'Traditional Wear', 'Bags & Shoes']),
  AdCategory('Events & Party Essentials', '${_c}cat_events.png',
      ['Canopy & Tents', 'Chairs & Tables', 'Sound System', 'Decorations']),
  AdCategory('Furniture', '${_c}cat_furniture.png',
      ['Sofas & Chairs', 'Beds', 'Tables', 'Shelves']),
  AdCategory('Tools & Equipment', '${_c}cat_tools.png',
      ['Toolbox', 'Power Drill', 'Generator', 'Ladders']),
  AdCategory('Mobile & Gadgets', '${_c}cat_mobile.png',
      ['Phones', 'Tablets', 'Laptops', 'Power Banks']),
  AdCategory('Baby & Kids', '${_c}cat_baby.png',
      ['Toys', 'Strollers', 'Baby Chairs', 'Kids Clothing']),
  AdCategory('Photography & Media', '${_c}cat_photography.png',
      ['Cameras', 'Lenses', 'Ring Lights', 'Tripods']),
  AdCategory('Travel & Outdoor', '${_c}cat_travel.png',
      ['Luggage', 'Tents', 'Coolers', 'Backpacks']),
  AdCategory('Services', '${_c}cat_services.png', [
    'Plumber',
    'Electrician',
    'Tailor',
    'Barber',
    'Hairdresser',
    'Makeup Artist',
    'Cleaner',
    'Painter',
    'Technician',
    'Mechanic',
    'Delivery Driver',
    'Errand Man',
    'Cooks',
    'Shortlets',
    'Car Wash / Cleaning',
  ], {
    'Plumber': '${_s}svc_plumber.png',
    'Electrician': '${_s}svc_electrician.png',
    'Tailor': '${_s}svc_tailor.png',
    'Barber': '${_s}svc_barber.png',
    'Hairdresser': '${_s}svc_hairdresser.png',
    'Makeup Artist': '${_s}svc_makeup.png',
    'Cleaner': '${_s}svc_cleaner.png',
    'Painter': '${_s}svc_painter.png',
    'Technician': '${_s}svc_technician.png',
    'Mechanic': '${_s}svc_mechanic.png',
    'Delivery Driver': '${_s}svc_delivery.png',
    'Errand Man': '${_s}svc_errand.png',
    'Cooks': '${_s}svc_errand.png',
    'Shortlets': '${_s}svc_errand.png',
    'Car Wash / Cleaning': '${_s}svc_cleaner.png',
  }),
];

/// Errand / task categories (equal to the server's `kind = task` labels).
const adTaskCategories = <String>[
  'Errand Running',
  'Delivery',
  'Cleaning',
  'Repairs',
  'Moving',
  'Shopping',
  'Pickup & Drop-off',
  'Other',
];

const adDeliveryOptions = <String>[
  'Pickup only',
  'Within my area',
  'Region',
  'Nationwide',
];
const adAvailabilityOptions = <String>[
  '24 hours',
  'Weekdays only',
  'Weekends only',
  'Business hours',
];
const adLendingPeriods = <String>[
  '1 day',
  '3 days',
  '1 week',
  '2 weeks',
  '1 month',
];

/// True when [label] is one of the "Services" sub categories.
bool isServiceCategory(String? label) =>
    label != null &&
    adCategories.any((c) => c.isService && c.subs.contains(label));

/// The top-level (server) category label that contains [sub], or null.
String? parentCategoryOf(String sub) {
  for (final c in adCategories) {
    if (c.subs.contains(sub)) return c.label;
  }
  return null;
}
