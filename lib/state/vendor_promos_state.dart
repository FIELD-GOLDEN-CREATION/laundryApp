import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo_offer.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

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
    this.isLoading = false,
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
  final bool isLoading;

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
    bool? isLoading,
  }) =>
      VendorPromosState(
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
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorPromosNotifier extends Notifier<VendorPromosState> {
  @override
  VendorPromosState build() => const VendorPromosState();

  Future<void> loadPromos() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getVendorPromos();
      final promos = data.map((j) => _fromJson(j)).toList();
      state = state.copyWith(promos: promos, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

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
    final name = state.promoName;
    if (name.isEmpty) return 'PROMO-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 4)}';
    final prefix = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').substring(0, name.length.clamp(0, 6));
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 4);
    return '$prefix-$suffix';
  }

  Future<void> createPromo() async {
    final code = generatePromoCode();
    final discount = double.tryParse(state.discountValue) ?? 0;
    final minSpendVal = double.tryParse(state.minSpend) ?? 0;
    final maxRedVal = int.tryParse(state.maxRedemptions);
    final end = state.endDate ?? DateTime.now().add(const Duration(days: 7));

    final body = {
      'code': code,
      'title': state.promoName,
      'discount_value': discount,
      'is_percentage': state.selectedDiscountType == 0,
      'min_spend': minSpendVal,
      'max_redemptions': maxRedVal,
      'target_category': state.targetCategory.isNotEmpty ? state.targetCategory : null,
      'target_item': state.targetItem.isNotEmpty ? state.targetItem : null,
      'applies_to': ['entire_order', 'specific_category', 'specific_item'][state.selectedAppliesTo],
      'audience': ['all_users', 'first_time', 'returning'][state.selectedAudience],
      'expires_at': end.toIso8601String(),
    };

    try {
      final data = await api.createVendorPromo(body);
      final j = data['data'] as Map<String, dynamic>? ?? data;
      final promo = _fromJson({...body.map((k, v) => MapEntry(k, v ?? '')), ...j});
      state = state.copyWith(promos: [...state.promos, promo]);
      resetForm();
    } on ApiException {
      // Keep state, caller can handle
    }
  }

  Future<void> togglePromoActive(String id) async {
    try {
      await api.toggleVendorPromo(id);
      state = state.copyWith(
        promos: state.promos.map((p) {
          if (p.id == id) return p.copyWith(isActive: !p.isActive);
          return p;
        }).toList(),
      );
    } on ApiException {
      // Keep state
    }
  }

  Future<void> deletePromo(String id) async {
    try {
      await api.deleteVendorPromo(id);
      state = state.copyWith(promos: state.promos.where((p) => p.id != id).toList());
    } on ApiException {
      // Keep state
    }
  }

  PromoOffer _fromJson(Map<String, dynamic> j) {
    return PromoOffer(
      id: j['id'] as String? ?? '',
      code: j['code'] as String? ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      discountValue: parseDouble(j['discount_value']) ?? 0,
      isPercentage: j['is_percentage'] as bool? ?? true,
      expiresAt: j['expires_at'] != null
          ? DateTime.tryParse(j['expires_at'] as String) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      imageUrl: j['image_url'] as String? ?? '',
      vendorName: j['vendor_name'] as String? ?? '',
      vendorId: j['vendor_id'] as String?,
      minSpend: parseDouble(j['min_spend']) ?? 0,
      appliesTo: _parseAppliesTo(j['applies_to'] as String?),
      targetCategory: j['target_category'] as String?,
      targetItem: j['target_item'] as String?,
      audience: _parseAudience(j['audience'] as String?),
      maxRedemptions: j['max_redemptions'] as int?,
      currentRedemptions: j['current_redemptions'] as int? ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
    );
  }

  PromoAppliesTo _parseAppliesTo(String? v) => switch (v) {
    'specific_category' => PromoAppliesTo.specificCategory,
    'specific_item' => PromoAppliesTo.specificItem,
    _ => PromoAppliesTo.entireOrder,
  };

  PromoAudience _parseAudience(String? v) => switch (v) {
    'first_time' => PromoAudience.firstTimeCustomers,
    'returning' => PromoAudience.returningCustomers,
    _ => PromoAudience.allUsers,
  };
}

final vendorPromosProvider = NotifierProvider<VendorPromosNotifier, VendorPromosState>(VendorPromosNotifier.new);
