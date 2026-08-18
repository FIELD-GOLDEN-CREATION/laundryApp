import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo_offer.dart';
import '../data/promo_mock_data.dart';

class VendorPromosState {
  const VendorPromosState({
    this.promos = const [],
    this.selectedDiscountType = 0,
    this.selectedAppliesTo = 0,
    this.selectedAudience = 0,
    this.promoName = '',
    this.discountValue = '',
    this.minSpend = '',
    this.maxRedemptions = '',
    this.targetCategory = '',
    this.targetItem = '',
    this.startDate,
    this.endDate,
  });

  final List<PromoOffer> promos;
  final int selectedDiscountType;
  final int selectedAppliesTo;
  final int selectedAudience;
  final String promoName;
  final String discountValue;
  final String minSpend;
  final String maxRedemptions;
  final String targetCategory;
  final String targetItem;
  final DateTime? startDate;
  final DateTime? endDate;

  VendorPromosState copyWith({
    List<PromoOffer>? promos,
    int? selectedDiscountType,
    int? selectedAppliesTo,
    int? selectedAudience,
    String? promoName,
    String? discountValue,
    String? minSpend,
    String? maxRedemptions,
    String? targetCategory,
    String? targetItem,
    DateTime? startDate,
    DateTime? endDate,
  }) => VendorPromosState(
    promos: promos ?? this.promos,
    selectedDiscountType: selectedDiscountType ?? this.selectedDiscountType,
    selectedAppliesTo: selectedAppliesTo ?? this.selectedAppliesTo,
    selectedAudience: selectedAudience ?? this.selectedAudience,
    promoName: promoName ?? this.promoName,
    discountValue: discountValue ?? this.discountValue,
    minSpend: minSpend ?? this.minSpend,
    maxRedemptions: maxRedemptions ?? this.maxRedemptions,
    targetCategory: targetCategory ?? this.targetCategory,
    targetItem: targetItem ?? this.targetItem,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );
}

class VendorPromosNotifier extends Notifier<VendorPromosState> {
  @override
  VendorPromosState build() => VendorPromosState(
    promos: promosForVendor('ld-p1'),
  );

  void setPromoName(String v) => state = state.copyWith(promoName: v);
  void setDiscountValue(String v) => state = state.copyWith(discountValue: v);
  void setMinSpend(String v) => state = state.copyWith(minSpend: v);
  void setMaxRedemptions(String v) => state = state.copyWith(maxRedemptions: v);
  void setTargetCategory(String v) => state = state.copyWith(targetCategory: v);
  void setTargetItem(String v) => state = state.copyWith(targetItem: v);
  void pickDiscountType(int i) => state = state.copyWith(selectedDiscountType: i);
  void pickAppliesTo(int i) => state = state.copyWith(selectedAppliesTo: i);
  void pickAudience(int i) => state = state.copyWith(selectedAudience: i);
  void setStartDate(DateTime d) => state = state.copyWith(startDate: d);
  void setEndDate(DateTime d) => state = state.copyWith(endDate: d);

  void resetForm() => state = state.copyWith(
    promoName: '',
    discountValue: '',
    minSpend: '',
    maxRedemptions: '',
    targetCategory: '',
    targetItem: '',
    selectedDiscountType: 0,
    selectedAppliesTo: 0,
    selectedAudience: 0,
    startDate: null,
    endDate: null,
  );

  String generatePromoCode() {
    final prefix = state.promoName.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').substring(0, state.promoName.length.clamp(0, 6));
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 4);
    return '$prefix-$suffix';
  }

  void createPromo() {
    final code = generatePromoCode();
    final discount = double.tryParse(state.discountValue) ?? 0;
    final minSpendVal = double.tryParse(state.minSpend) ?? 0;
    final maxRedVal = int.tryParse(state.maxRedemptions);
    final now = DateTime.now();
    final end = state.endDate ?? now.add(const Duration(days: 7));
    final appliesTo = [PromoAppliesTo.entireOrder, PromoAppliesTo.specificCategory, PromoAppliesTo.specificItem][state.selectedAppliesTo];
    final audience = [PromoAudience.allUsers, PromoAudience.firstTimeCustomers, PromoAudience.returningCustomers][state.selectedAudience];

    final promo = PromoOffer(
      id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      title: state.promoName,
      description: '${state.selectedDiscountType == 0 ? "${discount.round()}% off" : "TZS ${discount.round()} off"} ${appliesTo == PromoAppliesTo.entireOrder ? "entire order" : ""}',
      discountValue: discount,
      isPercentage: state.selectedDiscountType == 0,
      expiresAt: end,
      imageUrl: '',
      vendorName: 'Marina Fresh Laundry',
      vendorId: 'ld-p1',
      minSpend: minSpendVal,
      appliesTo: appliesTo,
      targetCategory: state.targetCategory.isNotEmpty ? state.targetCategory : null,
      targetItem: state.targetItem.isNotEmpty ? state.targetItem : null,
      audience: audience,
      maxRedemptions: maxRedVal,
      currentRedemptions: 0,
      isActive: true,
      createdAt: now,
    );

    state = state.copyWith(promos: [...state.promos, promo]);
    resetForm();
  }

  void togglePromoActive(String id) {
    final updated = state.promos.map((p) {
      if (p.id == id) return p.copyWith(isActive: !p.isActive);
      return p;
    }).toList();
    state = state.copyWith(promos: updated);
  }

  void deletePromo(String id) {
    state = state.copyWith(promos: state.promos.where((p) => p.id != id).toList());
  }
}

final vendorPromosProvider = NotifierProvider<VendorPromosNotifier, VendorPromosState>(VendorPromosNotifier.new);
