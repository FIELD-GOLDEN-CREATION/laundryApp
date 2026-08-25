import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_package.dart';
import '../services/api_service.dart';

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
    final kindStr = j['type'] as String? ?? 'weight';
    final kind = switch (kindStr) {
      'item_count' => PackageKind.itemCount,
      'household' => PackageKind.household,
      'subscription' => PackageKind.subscription,
      _ => PackageKind.weight,
    };
    return ServicePackage(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      tagline: j['tagline'] as String? ?? '',
      kind: kind,
      priceTzs: (j['price'] as num?)?.toDouble() ?? 0,
      priceUnit: j['price_unit'] as String? ?? '/ pack',
      inclusions: (j['inclusions'] as List?)?.cast<String>() ?? [],
      compareAtTzs: (j['compare_price'] as num?)?.toDouble(),
      note: j['note'] as String? ?? '',
      tag: j['tag'] as String? ?? '',
      serviceTags: (j['service_tags'] as List?)?.cast<String>() ?? [],
      active: j['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toJson(ServicePackage pkg) => {
    'name': pkg.name,
    'tagline': pkg.tagline,
    'type': pkg.kind.name,
    'price': pkg.priceTzs,
    'price_unit': pkg.priceUnit,
    'inclusions': pkg.inclusions,
    if (pkg.compareAtTzs != null) 'compare_price': pkg.compareAtTzs,
    'note': pkg.note,
    'tag': pkg.tag,
    'service_tags': pkg.serviceTags,
    'is_active': pkg.active,
  };
}

final vendorPackagesProvider =
    NotifierProvider<VendorPackagesNotifier, List<ServicePackage>>(VendorPackagesNotifier.new);

List<ServicePackage> activeVendorPackages(List<ServicePackage> all) => [
  for (final p in all)
    if (p.active) p,
].take(4).toList();
