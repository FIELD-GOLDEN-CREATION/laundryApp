import 'package:flutter/material.dart';

import '../models/saved_card.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Small colored pill naming a card's network — used wherever a saved card
/// is listed (Profile's "Saved cards" section, Checkout's card picker).
class CardBrandTag extends StatelessWidget {
  const CardBrandTag({super.key, required this.brand});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    final (Color bg, String label) = switch (brand) {
      CardBrand.visa => (const Color(0xFF1A1F71), 'VISA'),
      CardBrand.mastercard => (const Color(0xFFCC5A2B), 'MASTERCARD'),
      CardBrand.bank => (AppColors.slate, 'BANK CARD'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
      ),
    );
  }
}
