import 'package:flutter/widgets.dart';

/// A Tanzanian mobile-money operator offered at Checkout. [brand] and [mark]
/// back a small branded logo badge (see `MobileMoneyLogo`) so each provider
/// reads as its real network rather than a plain text row.
class MobileMoneyProvider {
  const MobileMoneyProvider({required this.name, required this.brand, required this.mark, required this.prefixes});

  final String name;

  /// The network's signature color, used as the logo tile background.
  final Color brand;

  /// Short wordmark rendered inside the logo tile, e.g. "M-PESA" / "airtel".
  final String mark;

  /// Leading digits (Tanzanian operator codes, e.g. '071') used to detect
  /// the network from the phone number as the customer types.
  final List<String> prefixes;
}
