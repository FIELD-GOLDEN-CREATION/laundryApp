/// The delivery/pickup fee and offered payment method ids the vendor set
/// when accepting an incoming order, captured by the "Accept order" sheet in
/// `widgets/vendor_accept_order_sheet.dart`. [paymentMethodIds] reference
/// [VendorPaymentMethod.id] entries from `vendorPaymentMethodsProvider` —
/// resolved live at display time so an edit to a saved method (e.g. fixing a
/// typo'd account number) is reflected on any order it was already offered on.
class VendorOrderAcceptance {
  const VendorOrderAcceptance({required this.fee, required this.paymentMethodIds});

  /// Raw TZS amount (digits only, e.g. "2400").
  final String fee;
  final List<String> paymentMethodIds;
}
