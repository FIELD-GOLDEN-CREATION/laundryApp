enum DiscountType { percentage, fixedAmount }

enum PromoAppliesTo { entireOrder, specificCategory, specificItem }

enum PromoAudience { allUsers, firstTimeCustomers, returningCustomers }

class PromoOffer {
  const PromoOffer({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountValue,
    required this.isPercentage,
    required this.expiresAt,
    required this.imageUrl,
    required this.vendorName,
    this.vendorId,
    this.minSpend = 0,
    this.appliesTo = PromoAppliesTo.entireOrder,
    this.targetCategory,
    this.targetItem,
    this.audience = PromoAudience.allUsers,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final double discountValue;
  final bool isPercentage;
  final DateTime expiresAt;
  final String imageUrl;
  final String vendorName;
  final String? vendorId;
  final double minSpend;
  final PromoAppliesTo appliesTo;
  final String? targetCategory;
  final String? targetItem;
  final PromoAudience audience;
  final int? maxRedemptions;
  final int currentRedemptions;
  final bool isActive;
  final DateTime? createdAt;

  String get discountLabel => isPercentage
      ? '${discountValue.round()}% off'
      : 'TZS ${discountValue.round()} off';

  String get audienceLabel {
    switch (audience) {
      case PromoAudience.allUsers:
        return 'All users';
      case PromoAudience.firstTimeCustomers:
        return 'First-time customers';
      case PromoAudience.returningCustomers:
        return 'Returning customers';
    }
  }

  String get appliesToLabel {
    switch (appliesTo) {
      case PromoAppliesTo.entireOrder:
        return 'Entire order';
      case PromoAppliesTo.specificCategory:
        return 'Category: ${targetCategory ?? ""}';
      case PromoAppliesTo.specificItem:
        return 'Item: ${targetItem ?? ""}';
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  String get countdownLabel {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expired';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    if (hours > 24) {
      final days = remaining.inDays;
      return '${days}d left';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  PromoOffer copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    double? discountValue,
    bool? isPercentage,
    DateTime? expiresAt,
    String? imageUrl,
    String? vendorName,
    String? vendorId,
    double? minSpend,
    PromoAppliesTo? appliesTo,
    String? targetCategory,
    String? targetItem,
    PromoAudience? audience,
    int? maxRedemptions,
    int? currentRedemptions,
    bool? isActive,
    DateTime? createdAt,
  }) => PromoOffer(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description ?? this.description,
    discountValue: discountValue ?? this.discountValue,
    isPercentage: isPercentage ?? this.isPercentage,
    expiresAt: expiresAt ?? this.expiresAt,
    imageUrl: imageUrl ?? this.imageUrl,
    vendorName: vendorName ?? this.vendorName,
    vendorId: vendorId ?? this.vendorId,
    minSpend: minSpend ?? this.minSpend,
    appliesTo: appliesTo ?? this.appliesTo,
    targetCategory: targetCategory ?? this.targetCategory,
    targetItem: targetItem ?? this.targetItem,
    audience: audience ?? this.audience,
    maxRedemptions: maxRedemptions ?? this.maxRedemptions,
    currentRedemptions: currentRedemptions ?? this.currentRedemptions,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
