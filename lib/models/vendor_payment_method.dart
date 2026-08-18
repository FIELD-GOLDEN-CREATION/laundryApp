enum VendorPaymentMethodKind { mobileMoney, bankTransfer, cashOnDelivery }

String vendorPaymentMethodKindLabel(VendorPaymentMethodKind kind) => switch (kind) {
  VendorPaymentMethodKind.mobileMoney => 'Mobile Money',
  VendorPaymentMethodKind.bankTransfer => 'Bank transfer',
  VendorPaymentMethodKind.cashOnDelivery => 'Cash on delivery',
};

/// A payout method the vendor can receive earnings on, managed from Vendor
/// Settings → "Payment methods". [provider]/[phone] apply to
/// [VendorPaymentMethodKind.mobileMoney]; [bankName]/[accountNumber]/
/// [accountHolder] apply to [VendorPaymentMethodKind.bankTransfer].
/// [VendorPaymentMethodKind.cashOnDelivery] carries no extra details — it's
/// a plain toggleable option with nothing for the vendor to fill in.
class VendorPaymentMethod {
  const VendorPaymentMethod({
    required this.id,
    required this.kind,
    this.provider,
    this.phone,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
  });

  final String id;
  final VendorPaymentMethodKind kind;

  final String? provider;
  final String? phone;

  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  String get title => switch (kind) {
    VendorPaymentMethodKind.mobileMoney => provider ?? 'Mobile Money',
    VendorPaymentMethodKind.bankTransfer => bankName ?? 'Bank transfer',
    VendorPaymentMethodKind.cashOnDelivery => 'Cash on delivery',
  };

  String get subtitle => switch (kind) {
    VendorPaymentMethodKind.mobileMoney => phone ?? '',
    VendorPaymentMethodKind.bankTransfer => '${accountHolder ?? ''} · •••• ${_last4(accountNumber)}',
    VendorPaymentMethodKind.cashOnDelivery => 'Collected in person at drop-off or delivery',
  };

  VendorPaymentMethod copyWith({
    String? provider,
    String? phone,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) => VendorPaymentMethod(
    id: id,
    kind: kind,
    provider: provider ?? this.provider,
    phone: phone ?? this.phone,
    bankName: bankName ?? this.bankName,
    accountNumber: accountNumber ?? this.accountNumber,
    accountHolder: accountHolder ?? this.accountHolder,
  );
}

String _last4(String? s) => (s == null || s.length < 4) ? (s ?? '') : s.substring(s.length - 4);
