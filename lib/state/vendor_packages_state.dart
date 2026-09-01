import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_package.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

class VendorPackagesNotifier extends Notifier<List<ServicePackage>> {
  @override
  List<ServicePackage> build() => [];

  Future<void> loadPackages() async {
    try {
      final data = await api.getVendorPackages();
      state = data.map((j) => _fromJson(j)).toList();
    } on ApiException {
      // Keep existing state
    }
  }

  Future<bool> createPackage(ServicePackage pkg) async {
    // Optimistic add — the package appears immediately and the API sync
    // replaces it with the server copy when available.
    state = [...state, pkg];
    try {
      final data = await api.createVendorPackage(_toJson(pkg));
      final j = data['data'] as Map<String, dynamic>? ?? data;
      final saved = _fromJson({..._toJson(pkg), ...j});
      state = [
        for (final p in state)
          if (p.id == pkg.id) saved else p,
      ];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePackage(String id, ServicePackage pkg) async {
    final prev = state;
    state = [
      for (final p in state)
        if (p.id == id) pkg else p,
    ];
    try {
      await api.updateVendorPackage(id, _toJson(pkg));
      return true;
    } catch (_) {
      state = prev;
      return false;
    }
  }

  Future<bool> removePackage(String id) async {
    final prev = state;
    state = state.where((p) => p.id != id).toList();
    try {
      await api.deleteVendorPackage(id);
      return true;
    } catch (_) {
      state = prev;
      return false;
    }
  }

  void toggleActive(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(active: !p.active) else p,
    ];
  }

  void setPrice(String id, double value) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(priceTzs: value.clamp(0, double.infinity)) else p,
    ];
  }

  ServicePackage _fromJson(Map<String, dynamic> j) {
    // Field names mirror the Laravel `packages` table/model (kind,
    // price_tzs, compare_at_tzs) — NOT the customer-facing shorthand this
    // used to send, which the backend's validator silently rejected.
    final kindStr = j['kind'] as String? ?? 'weight';
    final kind = switch (kindStr) {
      'itemCount' => PackageKind.itemCount,
      'household' => PackageKind.household,
      'subscription' => PackageKind.subscription,
      _ => PackageKind.weight,
    };
    return ServicePackage(
      id: '${j['id'] ?? ''}',
      name: j['name'] as String? ?? '',
      tagline: j['tagline'] as String? ?? '',
      kind: kind,
      priceTzs: parseDouble(j['price_tzs']) ?? 0,
      priceUnit: j['price_unit'] as String? ?? '/ pack',
      inclusions: (j['inclusions'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? e['label'] as String? ?? '' : '$e')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      compareAtTzs: parseDouble(j['compare_at_tzs']),
      note: j['note'] as String? ?? '',
      tag: j['tag'] as String? ?? '',
      // Eloquent snake_cases eager-loaded relation keys in JSON output, so
      // `serviceTags()` on the Package model comes back as `service_tags`.
      serviceTags: (j['service_tags'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? e['tag'] as String? ?? '' : '$e')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      active: j['is_active'] as bool? ?? true,
      packageItems: (j['items'] as List?)
              ?.map((e) {
                if (e is! Map<String, dynamic>) return null;
                return PackageItem(
                  itemId: '${e['item_id'] ?? ''}',
                  itemName: e['item_name'] as String? ?? '',
                  qty: parseDouble(e['qty'])?.toInt() ?? 0,
                  unitPrice: parseDouble(e['unit_price_tzs']) ?? 0,
                );
              })
              .whereType<PackageItem>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> _toJson(ServicePackage pkg) => {
    'name': pkg.name,
    'tagline': pkg.tagline,
    'kind': pkg.kind.name,
    // Sent as ints — the backend validates price_tzs/unit_price_tzs with
    // `integer`, which rejects a float-typed JSON value like 5000.0.
    'price_tzs': pkg.priceTzs.round(),
    'price_unit': pkg.priceUnit,
    'inclusions': pkg.inclusions,
    if (pkg.compareAtTzs != null) 'compare_at_tzs': pkg.compareAtTzs!.round(),
    'note': pkg.note,
    'tag': pkg.tag,
    'service_tags': pkg.serviceTags,
    'is_active': pkg.active,
    if (pkg.packageItems.isNotEmpty)
      'items': [
        for (final item in pkg.packageItems)
          {
            'item_id': int.tryParse(item.itemId) ?? 0,
            'item_name': item.itemName,
            'qty': item.qty,
            'unit_price_tzs': item.unitPrice.round(),
          },
      ],
  };
}

final vendorPackagesProvider =
    NotifierProvider<VendorPackagesNotifier, List<ServicePackage>>(VendorPackagesNotifier.new);

List<ServicePackage> activeVendorPackages(List<ServicePackage> all) => [
  for (final p in all)
    if (p.active) p,
].take(4).toList();
