import 'package:flutter/widgets.dart';

import '../models/address.dart';
import '../models/chat_message.dart';
import '../models/day_option.dart';
import '../models/menu_item.dart';
import '../models/mobile_money_provider.dart';
import '../models/notification_item.dart';
import '../models/offer.dart';
import '../models/order.dart';
import '../models/order_line.dart';
import '../models/shop.dart';
import '../models/track_step_def.dart';
import '../theme/colors.dart';
import '../utils/currency.dart';

/// Static seed data — a 1:1 port of the JS mock data in the source design
/// (there is no backend). This file is the single seam a future
/// repository/API layer would replace.

/// Unsplash photo URLs behind the shops/offers/payment card. Direct
/// `images.unsplash.com` image files (not the photo *page* links), so
/// `RemoteImage` renders the actual photos at runtime.
const _kShopPhotoWhite = 'https://images.unsplash.com/photo-1604335398980-ededcadcc37d?w=800&q=80';
const _kShopPhotoGrayA = 'https://images.unsplash.com/photo-1620912738725-1e5f0e49e97d?w=800&q=80';
const _kShopPhotoGrayB = 'https://images.unsplash.com/photo-1610305401607-8745a10c75dd?w=800&q=80';
const _kShopPhotoDryer = 'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=800&q=80';

/// Card-network photo used to illustrate the payment-card flows.
const kCardPhotoUrl = 'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?w=800&q=80';

const kOffers = [
  Offer(
    slotId: 'ld-offer-1',
    slotHint: 'Offer image',
    tag: 'Limited time',
    title: '40% off your first wash',
    sub: 'All services · T&C apply',
    imageUrl: _kShopPhotoWhite,
  ),
  Offer(
    slotId: 'ld-offer-2',
    slotHint: 'Offer image',
    tag: 'Bundle',
    title: 'Free ironing over TZS 78,000',
    sub: 'Wash & fold only',
    imageUrl: _kShopPhotoGrayA,
  ),
];

const kShops = [
  Shop(
    slotId: 'ld-p1',
    listSlotId: 'ld-p1l',
    name: 'Marina Fresh Laundry',
    rating: '4.8',
    meta: '1.2 km · Wash, iron, dry clean',
    price: 'from TZS 9,100/pc',
    badge: '24h',
    reviewCount: '312',
    distance: '1.2 km away',
    hours: 'Open till 8 PM',
    description:
        'A family-run shop that has been washing for the neighbourhood since '
        '2009. Everything is sorted by hand, and delicates get their own cycle.',
    badges: ['Free pickup', '24h turnaround', 'Eco detergent'],
    services: ['Wash', 'Iron', 'Dry clean'],
    ratingValue: 4.8,
    priceFromTzs: 9100,
    distanceKm: 1.2,
    is24h: true,
    isOpenNow: true,
    imageUrl: _kShopPhotoWhite,
  ),
  Shop(
    slotId: 'ld-p2',
    listSlotId: 'ld-p2l',
    name: 'Bright & Fold',
    rating: '4.9',
    meta: '2.0 km · Wash & fold specialists',
    price: 'from TZS 7,540/pc',
    badge: 'Free pickup',
    reviewCount: '486',
    distance: '2.0 km away',
    hours: 'Open till 9 PM',
    description:
        'Neighbourhood favourite for everyday wash & fold, with same-day '
        'turnaround on orders dropped off before noon and free doorstep pickup.',
    badges: ['Free pickup', 'Same-day', 'Fold & pack'],
    services: ['Wash & fold'],
    ratingValue: 4.9,
    priceFromTzs: 7540,
    distanceKm: 2.0,
    is24h: false,
    isOpenNow: true,
    imageUrl: _kShopPhotoGrayA,
  ),
  Shop(
    slotId: 'ld-p3',
    listSlotId: 'ld-p3l',
    name: 'Crisp Corner',
    rating: '4.7',
    meta: '2.8 km · Dry clean & suits',
    price: 'from TZS 20,800/pc',
    badge: 'Eco',
    reviewCount: '198',
    distance: '2.8 km away',
    hours: 'Open till 7 PM',
    description:
        'Specialists in suits, gowns and delicate fabrics, using eco-certified '
        'solvents and hand-finished pressing for a sharper, longer-lasting fit.',
    badges: ['Eco solvents', 'Suit specialists', 'Hand-pressed'],
    services: ['Dry clean', 'Suits'],
    ratingValue: 4.7,
    priceFromTzs: 20800,
    distanceKm: 2.8,
    is24h: false,
    isOpenNow: true,
    imageUrl: _kShopPhotoDryer,
  ),
  Shop(
    slotId: 'ld-p4',
    listSlotId: 'ld-p4l',
    name: 'Kariakoo Wash Hub',
    rating: '4.4',
    meta: '4.5 km · Budget wash & fold',
    price: 'from TZS 6,200/pc',
    badge: 'Budget',
    reviewCount: '221',
    distance: '4.5 km away',
    hours: 'Opens 8 AM',
    description:
        'High-volume budget laundromat in the heart of Kariakoo market, built '
        'for large loads and market-trader turnaround at the lowest price in town.',
    badges: ['Lowest price', 'Bulk orders', 'Market pickup'],
    services: ['Wash & fold', 'Ironing'],
    ratingValue: 4.4,
    priceFromTzs: 6200,
    distanceKm: 4.5,
    is24h: false,
    isOpenNow: false,
    imageUrl: _kShopPhotoGrayB,
  ),
  Shop(
    slotId: 'ld-p5',
    listSlotId: 'ld-p5l',
    name: 'Ilala Express Cleaners',
    rating: '4.6',
    meta: '3.6 km · Wash, iron, carpets',
    price: 'from TZS 12,400/pc',
    badge: '24h',
    reviewCount: '167',
    distance: '3.6 km away',
    hours: 'Open till 8 AM',
    description:
        'Round-the-clock service for Ilala\'s office workers, with a dedicated '
        'carpet and upholstery line alongside everyday wash and iron.',
    badges: ['24h turnaround', 'Carpet cleaning', 'Office accounts'],
    services: ['Wash', 'Iron', 'Carpet cleaning'],
    ratingValue: 4.6,
    priceFromTzs: 12400,
    distanceKm: 3.6,
    is24h: true,
    isOpenNow: true,
    imageUrl: _kShopPhotoWhite,
  ),
];

/// Returns the seeded shop whose [name] matches, if any.
Shop? shopByName(String name) {
  for (final s in kShops) {
    if (s.name == name) return s;
  }
  return null;
}

/// Returns the mobile-money operator whose [name] matches, if any.
MobileMoneyProvider? mobileProviderByName(String name) {
  for (final p in kMobileMoneyProviders) {
    if (p.name == name) return p;
  }
  return null;
}

/// Explore filters use each vendor's calculated distance from the customer's
/// current pickup location (`Shop.distanceKm`).
const kFilterOptions = [
  'Within 5 km',
  'Within 10 km',
  'Within 20 km',
  'Within 25 km',
  'Within 30 km',
  'Fast turnaround',
  'Open now',
  'Top rated',
];

const kMenuItems = [
  MenuItem(key: 'shirt', name: 'Shirts & tops', unit: 'Wash & fold, per piece', initial: 'S', price: 9100),
  MenuItem(key: 'trouser', name: 'Trousers', unit: 'Wash & press, per piece', initial: 'T', price: 11050),
  MenuItem(key: 'dress', name: 'Dress / suit', unit: 'Dry clean, per piece', initial: 'D', price: 24700),
  MenuItem(key: 'bed', name: 'Bed linen', unit: 'Wash & fold, per set', initial: 'B', price: 18200),
];

const kAddresses = [
  Address(label: 'Home', line: '12 Chole Road, Masaki, Apt 4B'),
  Address(label: 'Office', line: '8 Samora Avenue, Kisutu, 3rd Floor'),
];

const kDays = [
  DayOption(dow: 'Wed', num: '12'),
  DayOption(dow: 'Thu', num: '13'),
  DayOption(dow: 'Fri', num: '14'),
  DayOption(dow: 'Sat', num: '15'),
  DayOption(dow: 'Sun', num: '16'),
  DayOption(dow: 'Mon', num: '17'),
  DayOption(dow: 'Tue', num: '18'),
];

const kTimeSlots = ['8 – 10 AM', '10 – 12 PM', '2 – 4 PM', '6 – 8 PM'];

/// Tanzania mobile money operators offered at Checkout's "Mobile Money"
/// payment option — each with its network's signature color, wordmark and
/// operator prefixes so the picker auto-detects the network from the number.
const kMobileMoneyProviders = [
  MobileMoneyProvider(name: 'Mixx By Yas', brand: Color(0xFF6A1B9A), mark: 'Mixx', prefixes: ['066', '077']),
  MobileMoneyProvider(name: 'M-Pesa', brand: Color(0xFF00A651), mark: 'M-PESA', prefixes: ['071', '074', '075', '076']),
  MobileMoneyProvider(name: 'Airtel Money', brand: Color(0xFFED1C24), mark: 'airtel', prefixes: ['068', '069', '078', '079']),
  MobileMoneyProvider(name: 'HaloPesa', brand: Color(0xFFE6007E), mark: 'HaloPesa', prefixes: ['061', '062']),
];

/// Detects the operator from a Tanzanian number's leading digits (the first
/// three, e.g. '075' → M-Pesa), or null while there aren't enough digits yet.
MobileMoneyProvider? detectMobileProvider(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 3) return null;
  for (final p in kMobileMoneyProviders) {
    if (p.prefixes.any((prefix) => digits.startsWith(prefix))) return p;
  }
  return null;
}

const kTrackSteps = [
  TrackStepDef(title: 'Picked up', time: 'Wed, 9:12 AM'),
  TrackStepDef(title: 'Sorted & counted', time: 'Wed, 10:40 AM'),
  TrackStepDef(title: 'Washing in progress', time: 'Wed, 2:15 PM'),
  TrackStepDef(title: 'Out for delivery', time: 'Thu, 6:00 PM (est.)'),
];

const kSelfTrackSteps = [
  TrackStepDef(title: 'Dropped at shop', time: 'Promise arrival window'),
  TrackStepDef(title: 'Sorted & counted', time: 'On arrival'),
  TrackStepDef(title: 'Washing in progress', time: 'After drop-off'),
  TrackStepDef(title: 'Ready for collection', time: 'Thu, 6:00 PM (est.)'),
];

const kActiveOrders = [
  Order(
    shop: 'Marina Fresh Laundry',
    id: '#LD-2481',
    items: '8 items',
    status: 'Washing',
    statusFg: AppColors.teal,
    statusBg: AppColors.tealMuted,
    date: 'Picked up Wed, 9:12 AM',
    total: 'TZS 90,350',
    trackStep: 2,
  ),
  Order(
    shop: 'Bright & Fold',
    id: '#LD-2477',
    items: '3 items',
    status: 'Scheduled',
    statusFg: AppColors.amber,
    statusBg: AppColors.amberLight,
    date: 'Pickup Fri, 10 – 12 PM',
    total: 'TZS 32,240',
    trackStep: kOrderPlacedStep,
  ),
];

const kCompletedOrders = [
  Order(
    shop: 'Crisp Corner',
    id: '#LD-2390',
    items: '2 suits',
    status: 'Delivered',
    statusFg: AppColors.muted,
    statusBg: AppColors.creamDark,
    date: 'Jul 28',
    total: 'TZS 49,400',
    trackStep: 3,
  ),
  Order(
    shop: 'Marina Fresh Laundry',
    id: '#LD-2361',
    items: '11 items',
    status: 'Delivered',
    statusFg: AppColors.muted,
    statusBg: AppColors.creamDark,
    date: 'Jul 19',
    total: 'TZS 107,120',
    trackStep: 3,
  ),
];

final kInitialChatMessages = [
  const ChatMessage(isMe: false, text: 'Hi Amara! We picked up your bag — 8 items logged.', time: '9:12 AM'),
  const ChatMessage(isMe: true, text: 'Thanks! The linen shirt needs a gentle wash please.', time: '9:14 AM'),
  const ChatMessage(
    isMe: false,
    text: 'Noted, we will run it on delicate. Delivery still on for Thursday 6 PM.',
    time: '9:15 AM',
  ),
];

const kNotifications = [
  NotificationItem(
    initial: 'W',
    title: 'Your laundry is being washed',
    body: 'Order #LD-2481 moved to the wash cycle. Delivery still on for Thursday 6 PM.',
    time: '12 min ago',
    bg: AppColors.white,
    iconBg: AppColors.tealMuted,
    iconFg: AppColors.teal,
  ),
  NotificationItem(
    initial: '%',
    title: '40% off your next wash',
    body: 'A thank-you for your 24th order. Valid until Sunday.',
    time: '2 hours ago',
    bg: AppColors.amberLight,
    iconBg: AppColors.white,
    iconFg: AppColors.amber,
  ),
  NotificationItem(
    initial: 'D',
    title: 'Daniel is on the way',
    body: 'Your driver will arrive between 10 and 12.',
    time: 'Yesterday',
    bg: AppColors.white,
    iconBg: AppColors.tealMuted,
    iconFg: AppColors.teal,
  ),
  NotificationItem(
    initial: '★',
    title: 'How did we do?',
    body: 'Rate Crisp Corner for order #LD-2390.',
    time: 'Jul 29',
    bg: AppColors.white,
    iconBg: AppColors.creamDark,
    iconFg: AppColors.slate,
  ),
];

const kPreferenceLabels = ['Push notifications', 'Eco detergent by default', 'Contactless pickup'];
const kDefaultPrefsOn = [true, true, false];

/// Cart math — pure functions ported from the source's `sub()`/`count()`.
double cartSubtotal(Map<String, int> qty, [List<MenuItem> extra = const []]) {
  var total = 0.0;
  for (final item in [...kMenuItems, ...extra]) {
    total += item.price * (qty[item.key] ?? 0);
  }
  return total;
}

int cartItemCount(Map<String, int> qty, [List<MenuItem> extra = const []]) {
  var total = 0;
  for (final item in [...kMenuItems, ...extra]) {
    total += qty[item.key] ?? 0;
  }
  return total;
}

List<OrderLine> cartLines(Map<String, int> qty, List<MenuItem> extra) => [
  for (final item in [...kMenuItems, ...extra])
    if ((qty[item.key] ?? 0) > 0) OrderLine(name: item.name, qty: qty[item.key]!, unitPrice: item.price),
];

String formatMoney(double n) => formatTzs(n);
