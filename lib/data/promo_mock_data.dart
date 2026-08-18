import '../models/promo_offer.dart';

final kPromoOffers = [
  PromoOffer(
    id: 'promo-1',
    code: 'MARINA15-A3K9',
    title: '15% Off Your First Wash',
    description: 'Get 15% off your first wash & fold order. Minimum spend TZS 20,000.',
    discountValue: 15,
    isPercentage: true,
    expiresAt: DateTime.now().add(const Duration(hours: 6, minutes: 32)),
    imageUrl: 'https://images.unsplash.com/photo-1604335398980-ededcadcc37d?w=800&q=80',
    vendorName: 'Marina Fresh Laundry',
    vendorId: 'ld-p1',
    minSpend: 20000,
    appliesTo: PromoAppliesTo.entireOrder,
    audience: PromoAudience.firstTimeCustomers,
    currentRedemptions: 47,
    maxRedemptions: 200,
    createdAt: DateTime.now().subtract(const Duration(hours: 48)),
  ),
  PromoOffer(
    id: 'promo-2',
    code: 'BRIGHT5K-M2X7',
    title: 'TZS 5,000 Off Dry Cleaning',
    description: 'Flat TZS 5,000 off any dry cleaning service. No minimum spend.',
    discountValue: 5000,
    isPercentage: false,
    expiresAt: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
    imageUrl: 'https://images.unsplash.com/photo-1620912738725-1e5f0e49e97d?w=800&q=80',
    vendorName: 'Bright & Fold',
    vendorId: 'ld-p2',
    minSpend: 0,
    appliesTo: PromoAppliesTo.specificCategory,
    targetCategory: 'Formal, Woolen & Outerwear',
    audience: PromoAudience.allUsers,
    currentRedemptions: 12,
    maxRedemptions: 50,
    createdAt: DateTime.now().subtract(const Duration(hours: 24)),
  ),
  PromoOffer(
    id: 'promo-3',
    code: 'CRISP20-P4N8',
    title: '20% Off Suits',
    description: '20% off all suit cleaning. Perfect for weddings and events.',
    discountValue: 20,
    isPercentage: true,
    expiresAt: DateTime.now().add(const Duration(days: 3, hours: 12)),
    imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
    vendorName: 'Crisp Corner',
    vendorId: 'ld-p3',
    minSpend: 15000,
    appliesTo: PromoAppliesTo.specificCategory,
    targetCategory: 'Formal, Woolen & Outerwear',
    audience: PromoAudience.returningCustomers,
    currentRedemptions: 8,
    maxRedemptions: 30,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  PromoOffer(
    id: 'promo-4',
    code: 'PLATFORM-FREE',
    title: 'Free Pickup & Delivery',
    description: 'Free pickup and delivery on all orders over TZS 50,000.',
    discountValue: 3500,
    isPercentage: false,
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&q=80',
    vendorName: 'All Vendors',
    vendorId: null,
    minSpend: 50000,
    appliesTo: PromoAppliesTo.entireOrder,
    audience: PromoAudience.allUsers,
    currentRedemptions: 156,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

PromoOffer? findPromoByCode(String code) {
  try {
    return kPromoOffers.firstWhere((p) => p.code == code.toUpperCase());
  } catch (_) {
    return null;
  }
}

List<PromoOffer> activePromos() => kPromoOffers.where((p) => p.isActive && !p.isExpired).toList();

List<PromoOffer> promosForVendor(String vendorId) =>
    kPromoOffers.where((p) => p.vendorId == vendorId && p.isActive).toList();
