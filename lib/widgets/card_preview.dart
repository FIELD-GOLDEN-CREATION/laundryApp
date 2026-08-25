import 'package:flutter/material.dart';

import '../models/saved_card.dart';
import '../theme/text_styles.dart';
import 'remote_image.dart';

/// Card artwork — display asset, not business data.
const kCardArtUrl = 'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?w=800&q=80';

/// Credit-card visual for the card-payment sheet â€” the Visa photo with a
/// gradient overlay, showing the live (or selected saved) card details.
class CardPreview extends StatelessWidget {
  const CardPreview({super.key, required this.brand, required this.number, required this.name, required this.expiry});

  final CardBrand brand;
  final String number;
  final String name;
  final String expiry;

  String get _formattedNumber {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) sb.write(' ');
      sb.write(i < digits.length ? digits[i] : 'â€¢');
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RemoteImage(url: kCardArtUrl, fallback: 'Card', placeholder: ColoredBox(color: Color(0xFF2C3E50))),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.15)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PAYMENT CARD',
                        style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.6),
                      ),
                      Text(
                        brandLabel(brand).toUpperCase(),
                        style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formattedNumber,
                    style: AppText.sans(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'CARD HOLDER' : name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.4),
                        ),
                      ),
                      Text(
                        expiry.isEmpty ? 'MM/YY' : expiry,
                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
