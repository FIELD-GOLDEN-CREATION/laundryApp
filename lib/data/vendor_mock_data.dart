import '../models/addon_toggle.dart';
import '../models/alert_item.dart';
import '../models/chat_message.dart';
import '../models/day_option.dart';
import '../models/machine_status.dart';
import '../models/menu_price_row.dart';
import '../models/order_line.dart';
import '../models/payout_record.dart';
import '../models/review_item.dart';
import '../models/track_step_def.dart';
import '../models/turnaround_option.dart';
import '../models/vendor_order.dart';
import '../theme/colors.dart';

/// Static seed data for the Vendor module — same 1:1 port-of-the-JS-mock
/// approach as data/mock_data.dart, split into its own file since the
/// combined customer+vendor+admin dataset would otherwise make one file
/// unwieldy.

const kWeekBarFractions = [.38, .52, .44, .68, .60, .82, 1.0];

/// Trailing 7 days ending on "today" (Wednesday, the last/amber bar) —
/// paired 1:1 with [kWeekBarFractions] for the dashboard revenue chart.
const kWeekBarLabels = ['Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed'];

const kVendorAlerts = [
  AlertItem(
    title: '#LD-2486 · express, 6h left',
    sub: 'Wedding dress · dry clean only',
    tag: 'Urgent',
    accentColor: AppColors.amber,
    tagBg: AppColors.amberLight,
  ),
  AlertItem(
    title: '#LD-2479 · pickup overdue',
    sub: 'Driver has not collected · 40 min late',
    tag: 'Late',
    accentColor: AppColors.amber,
    tagBg: AppColors.amberLight,
  ),
];

const kMachines = [
  MachineStatus(name: 'Washer 1 – 12 kg', state: 'Rinse · 14 min', pct: 0.72, color: AppColors.teal),
  MachineStatus(name: 'Washer 2 – 12 kg', state: 'Spin · 4 min', pct: 0.90, color: AppColors.teal),
  MachineStatus(name: 'Dryer 1 – 10 kg', state: 'Idle', pct: 0, color: AppColors.tabInactive),
  MachineStatus(name: 'Press station', state: 'Queue of 6', pct: 0.55, color: AppColors.amber),
];

const kVendorOrdersNew = [
  VendorOrder(
    id: '#LD-2492',
    customer: 'Nina Alvarez',
    items: '6 items',
    dist: '0.8 km',
    priority: 'Express',
    chips: ['Dry clean', 'Silk'],
    when: 'Requested 4 min ago',
    total: 'TZS 135,200',
    stage: 'new',
    fulfillment: 'delivery',
    subtotalTzs: 135200,
    customerPhone: '+255 712 345 678',
    customerAddress: '12 Chole Road, Masaki, Apt 4B',
  ),
  VendorOrder(
    id: '#LD-2491',
    customer: 'Owen Park',
    items: '12 items',
    dist: '1.4 km',
    priority: 'Standard',
    chips: ['Wash & fold'],
    when: 'Requested 11 min ago',
    total: 'TZS 99,840',
    stage: 'new',
    fulfillment: 'delivery',
    subtotalTzs: 99840,
    customerPhone: '+255 765 432 109',
    customerAddress: '8 Haile Selassie Road, Oysterbay',
  ),
  VendorOrder(
    id: '#LD-2490',
    customer: 'Hana Sato',
    items: '3 items',
    dist: '2.1 km',
    priority: 'Standard',
    chips: ['Ironing', 'Same day'],
    when: 'Requested 22 min ago',
    total: 'TZS 37,050',
    stage: 'new',
    fulfillment: 'self',
    subtotalTzs: 37050,
    customerPhone: '+255 789 012 345',
    customerAddress: '',
  ),
];

const kVendorOrdersWip = [
  VendorOrder(
    id: '#LD-2481',
    customer: 'Amara Reed',
    items: '8 items',
    dist: '1.2 km',
    priority: 'Standard',
    chips: ['Washing', 'Delicate'],
    when: 'Washer 2 · 14 min left',
    total: 'TZS 90,350',
    stage: 'wip',
  ),
  VendorOrder(
    id: '#LD-2486',
    customer: 'Luis Ferrer',
    items: '1 dress',
    dist: '0.5 km',
    priority: 'Express',
    chips: ['Dry clean', '6h left'],
    when: 'Press queue',
    total: 'TZS 119,600',
    stage: 'wip',
  ),
];

/// Vendor-side view of the same "Amara Reed" / #LD-2481 conversation seeded
/// in [kInitialChatMessages] — same three messages, `isMe` flipped since the
/// vendor is now the sender of the shop's replies.
const kInitialVendorChatMessages = [
  ChatMessage(isMe: true, text: 'Hi Amara! We picked up your bag — 8 items logged.', time: '9:12 AM'),
  ChatMessage(isMe: false, text: 'Thanks! The linen shirt needs a gentle wash please.', time: '9:14 AM'),
  ChatMessage(
    isMe: true,
    text: 'Noted, we will run it on delicate. Delivery still on for Thursday 6 PM.',
    time: '9:15 AM',
  ),
];

const kVendorOrdersReady = [
  VendorOrder(
    id: '#LD-2478',
    customer: 'Grace Bello',
    items: '9 items',
    dist: '1.9 km',
    priority: 'Standard',
    chips: ['Ready', 'Awaiting driver'],
    when: 'Packed 12:40 PM',
    total: 'TZS 106,860',
    stage: 'ready',
  ),
  VendorOrder(
    id: '#LD-2475',
    customer: 'Ivan Petrov',
    items: '4 items',
    dist: '3.0 km',
    priority: 'Standard',
    chips: ['Ready'],
    when: 'Packed 11:05 AM',
    total: 'TZS 58,500',
    stage: 'ready',
  ),
];

const kGarmentLabels = ['Shirts ×4', 'Trousers ×2', 'Dress ×1', 'Linen ×1'];

/// Packages and per-piece services the customer picked when placing order
/// #LD-2481 — read-only on the Vendor Order Detail screen.
const kOrderLineItems = [
  OrderLine(name: 'The Student Bag', qty: 1, unitPrice: 34000),
  OrderLine(name: 'Ironing', qty: 3, unitPrice: 5200),
  OrderLine(name: 'Delicate fabric treatment', qty: 1, unitPrice: 10400),
];

const kDamageLabels = [
  'Fading on collar (shirt 2)',
  'Loose seam on trousers',
  'Bleach mark on linen',
  'Missing button',
];
const kDefaultDamageChecked = [true, false, false, false];

const kProcessingSteps = [
  TrackStepDef(title: 'Received', time: '9:12 AM'),
  TrackStepDef(title: 'Sorted & tagged', time: '10:40 AM'),
  TrackStepDef(title: 'Washing', time: '2:15 PM'),
  TrackStepDef(title: 'Drying & pressing', time: '4:05 PM'),
  TrackStepDef(title: 'Ready for delivery', time: '—'),
];

const kCategoryLabels = [
  'Standard Everyday Wear',
  'Formal, Woolen & Outerwear',
  'Footwear & Bags Care',
  'Bedding, Household & Heavy Fabrics',
  'Bulk Services & Add-Ons',
];
const kDefaultCategoriesOn = [true, true, true, true, true];

const kMenuPriceRows = [
  MenuPriceRow(key: 'tshirt', name: 'T-Shirt / Polo', unit: 'per piece'),
  MenuPriceRow(key: 'shirt', name: 'Casual Shirt / Blouse', unit: 'per piece'),
  MenuPriceRow(key: 'trouser', name: 'Trousers / Jeans', unit: 'per piece'),
  MenuPriceRow(key: 'suit', name: '2-Piece Suit', unit: 'per set'),
  MenuPriceRow(key: 'coat', name: 'Heavy Coat', unit: 'per piece'),
  MenuPriceRow(key: 'sneakers', name: 'Sneakers', unit: 'per pair'),
  MenuPriceRow(key: 'blanket', name: 'Blanket', unit: 'per piece'),
  MenuPriceRow(key: 'bedsheet', name: 'Bedsheet', unit: 'per piece'),
];
const kDefaultVendorPrices = {
  'tshirt': 2250.0,
  'shirt': 3000.0,
  'trouser': 3500.0,
  'suit': 9500.0,
  'coat': 11500.0,
  'sneakers': 6000.0,
  'blanket': 6500.0,
  'bedsheet': 3000.0,
};

const kTurnaroundOptions = [
  TurnaroundOption(label: '6h', sub: 'Express +40%'),
  TurnaroundOption(label: '24h', sub: 'Standard'),
  TurnaroundOption(label: '48h', sub: 'Economy −10%'),
];

const kAddonToggles = [
  AddonToggle(label: 'Delicate fabric treatment', price: '+TZS 10,400'),
  AddonToggle(label: 'Stain removal (deep)', price: '+TZS 16,900'),
  AddonToggle(label: 'Eco detergent', price: '+TZS 3,900 · upsell'),
  AddonToggle(label: 'Fabric softener & scent', price: '+TZS 5,200'),
];
const kDefaultAddonsOn = [true, false, true, true];

const kReturnDays = [
  DayOption(dow: 'Thu', num: '13'),
  DayOption(dow: 'Fri', num: '14'),
  DayOption(dow: 'Sat', num: '15'),
  DayOption(dow: 'Sun', num: '16'),
  DayOption(dow: 'Mon', num: '17'),
];

const kMonthBars = [
  ('Mar', .48),
  ('Apr', .62),
  ('May', .55),
  ('Jun', .74),
  ('Jul', .88),
  ('Aug', 1.0),
];

const kPayouts = [
  PayoutRecord(date: '7 Aug 2026', ref: 'Bank transfer · •••• 8821', amount: 'TZS 7,644,260'),
  PayoutRecord(date: '31 Jul 2026', ref: 'Bank transfer · •••• 8821', amount: 'TZS 8,809,970'),
  PayoutRecord(date: '24 Jul 2026', ref: 'Bank transfer · •••• 8821', amount: 'TZS 7,051,200'),
];

const kReviews = [
  ReviewItem(
    name: 'Amara R.',
    stars: '★★★★★',
    text: 'They flagged a stain before washing and sent a photo. That is service.',
  ),
  ReviewItem(
    name: 'Tomas L.',
    stars: '★★★★☆',
    text: 'Fast turnaround, though the express order arrived an hour late.',
  ),
  ReviewItem(name: 'Priya N.', stars: '★★★★★', text: 'Eco detergent option is worth the extra dollar fifty.'),
];

/// Vendor Settings screen seed data (`state/vendor_profile_state.dart`).
const kWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Default working days: Monday, Wednesday, Thursday and Sunday.
const kDefaultWorkingDays = [true, false, true, true, false, false, true];

const kVendorTimeOptions = [
  '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
  '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM',
  '8:00 PM', '9:00 PM', '10:00 PM', '11:00 PM',
];

const kDefaultVendorShopPhotos = ['Storefront', 'Interior', 'Machines'];

const kVendorLanguageOptions = ['English', 'Swahili'];
