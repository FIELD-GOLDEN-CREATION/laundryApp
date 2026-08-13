import 'package:flutter/material.dart';

import '../models/mobile_money_provider.dart';
import '../theme/text_styles.dart';

/// Branded logo tile for a mobile-money network — a rounded square in the
/// operator's signature color carrying its wordmark, so each provider in the
/// Checkout picker reads as its real network rather than a plain text row.
class MobileMoneyLogo extends StatelessWidget {
  const MobileMoneyLogo({super.key, required this.provider, this.size = 40});

  final MobileMoneyProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: provider.brand,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          provider.mark,
          style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
        ),
      ),
    );
  }
}
