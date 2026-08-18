import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_payment_method.dart';

/// The vendor's payout methods, edited from Vendor Settings → "Payment
/// methods". Starts empty — methods only exist once the vendor adds one.
class VendorPaymentMethodsNotifier extends Notifier<List<VendorPaymentMethod>> {
  @override
  List<VendorPaymentMethod> build() => [];

  void add(VendorPaymentMethod method) => state = [...state, method];

  void update(VendorPaymentMethod method) =>
      state = [for (final m in state) if (m.id == method.id) method else m];

  void remove(String id) => state = state.where((m) => m.id != id).toList();
}

final vendorPaymentMethodsProvider =
    NotifierProvider<VendorPaymentMethodsNotifier, List<VendorPaymentMethod>>(VendorPaymentMethodsNotifier.new);
