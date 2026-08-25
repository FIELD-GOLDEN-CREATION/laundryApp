import 'package:flutter/material.dart';

import '../models/mobile_money_provider.dart';

/// Tanzania mobile money operators offered at Checkout's "Mobile Money"
/// payment option — each with its network's signature color, wordmark and
/// operator prefixes so the picker auto-detects the network from the number.
const kMobileMoneyProviders = [
  MobileMoneyProvider(name: 'Mixx By Yas', brand: Color(0xFF6A1B9A), mark: 'Mixx', prefixes: ['066', '077']),
  MobileMoneyProvider(name: 'M-Pesa', brand: Color(0xFF00A651), mark: 'M-PESA', prefixes: ['071', '074', '075', '076']),
  MobileMoneyProvider(name: 'Airtel Money', brand: Color(0xFFED1C24), mark: 'airtel', prefixes: ['068', '069', '078', '079']),
  MobileMoneyProvider(name: 'HaloPesa', brand: Color(0xFFE6007E), mark: 'HaloPesa', prefixes: ['061', '062']),
];

MobileMoneyProvider? mobileProviderByName(String name) {
  for (final p in kMobileMoneyProviders) {
    if (p.name == name) return p;
  }
  return null;
}

/// Detects the operator from a Tanzanian number's leading digits (the first
/// three, e.g. '075' → M-Pesa), or null while there aren't enough digits yet.
MobileMoneyProvider? detectMobileProvider(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 3) return null;
  for (final p in kMobileMoneyProviders) {
    if (p.prefixes.any((prefix) => digits.startsWith(prefix))) return p;
  }
  return null;
}
