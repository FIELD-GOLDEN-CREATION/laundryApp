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
    this.targetCategoryId,
    this.targetCategoryName = '',
    this.targetItemId,
    this.targetItemName = '',
    this.targetPackageId,
    this.targetPackageName = '',
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

  /// Real backend category/item ids picked from the vendor's own catalog —
  /// the backend only accepts an id matching an existing row, so this can't
  /// be free text the way it used to be.
  final String? targetCategoryId;
  final String targetCategoryName;
  final String? targetItemId;
  final String targetItemName;
  final String? targetPackageId;
  final String targetPackageName;
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
    String? targetCategoryId,
    String? targetCategoryName,
    String? targetItemId,
    String? targetItemName,
    String? targetPackageId,
    String? targetPackageName,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    bool clearTarget = false,
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
        targetCategoryId: clearTarget ? null : (targetCategoryId ?? this.targetCategoryId),
        targetCategoryName: clearTarget ? '' : (targetCategoryName ?? this.targetCategoryName),
        targetItemId: clearTarget ? null : (targetItemId ?? this.targetItemId),
        targetItemName: clearTarget ? '' : (targetItemName ?? this.targetItemName),
        targetPackageId: clearTarget ? null : (targetPackageId ?? this.targetPackageId),
        targetPackageName: clearTarget ? '' : (targetPackageName ?? this.targetPackageName),
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
  void pickTargetCategory(String id, String name) =>
      state = state.copyWith(targetCategoryId: id, targetCategoryName: name);
  void pickTargetItem(String id, String name) =>
      state = state.copyWith(targetItemId: id, targetItemName: name);
  void pickTargetPackage(String id, String name) =>
      state = state.copyWith(targetPackageId: id, targetPackageName: name);
  void pickDiscountType(int i) => state = state.copyWith(selectedDiscountType: i);
  // Switching scope invalidates whatever category/item/package was picked
  // under the old scope, so clear it rather than leave a stale, unreachable
  // selection.
  void pickAppliesTo(int i) => state = state.copyWith(selectedAppliesTo: i, clearTarget: true);
  void pickAudience(int i) => state = state.copyWith(selectedAudience: i);
  void setStartDate(DateTime d) => state = state.copyWith(startDate: d);
  void setEndDate(DateTime d) => state = state.copyWith(endDate: d);

  void resetForm() => state = state.copyWith(
    promoName: '',
    discountValue: '',
    minSpend: '',
    maxRedemptions: '',
    clearTarget: true,
    selectedDiscountType: 0,
    selectedAppliesTo: 0,
    selectedAudience: 0,
    startDate: null,
    endDate: null,
  );

  String generatePromoCode() {
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 4);
    // Letters-only prefix from the promo name — e.g. "10% Off" strips down to
    // "OFF". Clamping against the ORIGINAL name's length (before stripping)
    // could ask for more characters than the stripped string actually has
    // (a name like "10% Off" is 7 chars but "OFF" is only 3), which threw a
    // RangeError on `substring` and silently aborted promo creation.
    final letters = state.promoName.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (letters.isEmpty) return 'PROMO-$suffix';
    final prefix = letters.substring(0, letters.length.clamp(0, 6));
    return '$prefix-$suffix';
  }

  /// Whether the current form is complete enough to submit — mirrors the
  /// backend's `required_if` on target_category_id/target_item_id/
  /// target_package_id, so the UI can block before hitting a validation
  /// error.
  bool get canSubmit {
    if (state.promoName.trim().isEmpty || state.discountValue.trim().isEmpty) return false;
    if (state.selectedAppliesTo == 1 && state.targetCategoryId == null) return false;
    if (state.selectedAppliesTo == 2 && state.targetItemId == null) return false;
    if (state.selectedAppliesTo == 3 && state.targetPackageId == null) return false;
    return true;
  }

  Future<bool> createPromo() async {
    if (!canSubmit) return false;

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
      // Backend column is `min_spend_tzs`, validated as an integer.
      'min_spend_tzs': minSpendVal.round(),
      'max_redemptions': maxRedVal,
      // `applies_to`/`audience` are validated against these exact camelCase
      // enum values — the backend rejects anything else outright (this was
      // the actual reason promos never made it past creation).
      'applies_to': ['entireOrder', 'specificCategory', 'specificItem', 'specificPackage', 'delivery'][state.selectedAppliesTo],
      'audience': ['allUsers', 'firstTimeCustomers', 'returningCustomers'][state.selectedAudience],
      if (state.selectedAppliesTo == 1 && state.targetCategoryId != null)
        'target_category_id': int.tryParse(state.targetCategoryId!),
      if (state.selectedAppliesTo == 2 && state.targetItemId != null)
        'target_item_id': int.tryParse(state.targetItemId!),
      if (state.selectedAppliesTo == 3 && state.targetPackageId != null)
        'target_package_id': int.tryParse(state.targetPackageId!),
      'expires_at': end.toIso8601String(),
    };

    try {
      final data = await api.createVendorPromo(body);
      final j = data['data'] as Map<String, dynamic>? ?? data;
      final promo = _fromJson({...body.map((k, v) => MapEntry(k, v ?? '')), ...j});
      state = state.copyWith(promos: [...state.promos, promo]);
      resetForm();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> togglePromoActive(String id) async {
    PromoOffer? promo;
    for (final p in state.promos) {
      if (p.id == id) {
        promo = p;
        break;
      }
    }
    if (promo == null) return false;
    try {
      // There is no `/vendor/promos/{id}/toggle` route on the backend —
      // only GET/POST/PUT/DELETE on `/vendor/promos` exist, so this always
      // 404'd. Flip the flag through the update endpoint instead.
      await api.updateVendorPromo(id, {'is_active': !promo.isActive});
      state = state.copyWith(
        promos: state.promos.map((p) {
          if (p.id == id) return p.copyWith(isActive: !p.isActive);
          return p;
        }).toList(),
      );
      return true;
    } on ApiException {
      return false;
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
      // Backend returns `id` as an int — `as String?` throws on a type
      // mismatch instead of returning null, which broke this parse for
      // every real promo (not just newly-created ones), uncaught by the
      // `on ApiException` handlers around every call site of this method.
      id: j['id'] != null ? '${j['id']}' : '',
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
      minSpend: parseDouble(j['min_spend_tzs']) ?? 0,
      appliesTo: promoAppliesToFromJson(j['applies_to'] as String?),
      targetCategory: j['target_category_id'] != null ? '${j['target_category_id']}' : null,
      targetItem: j['target_item_id'] != null ? '${j['target_item_id']}' : null,
      targetPackage: j['target_package_id'] != null ? '${j['target_package_id']}' : null,
      audience: _parseAudience(j['audience'] as String?),
      maxRedemptions: parseInt(j['max_redemptions']),
      currentRedemptions: parseInt(j['current_redemptions']) ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
    );
  }

  PromoAudience _parseAudience(String? v) => switch (v) {
    'firstTimeCustomers' => PromoAudience.firstTimeCustomers,
    'returningCustomers' => PromoAudience.returningCustomers,
    _ => PromoAudience.allUsers,
  };
}

final vendorPromosProvider = NotifierProvider<VendorPromosNotifier, VendorPromosState>(VendorPromosNotifier.new);
