import 'package:flutter/material.dart';

import '../../../models/offer.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/remote_image.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onClaim});

  final Offer offer;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 296,
      // Taller than the source's literal 158px: Google Fonts' metrics for
      // Inter run taller than the browser defaults the original CSS assumed,
      // so this card needs the extra room to avoid clipping the two-line title.
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(22)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Unlike the shop/map placeholders, most of this card stays
          // visible under the gradient (it's meant to read as a photo
          // filling the whole tile). A transparent placeholder keeps the
          // teal fill below showing through whenever there's no real photo.
          Container(color: const Color(0xFF2A7D78)),
          RemoteImage(url: offer.imageUrl, fallback: offer.slotHint, placeholder: const SizedBox.shrink()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.teal.withValues(alpha: 0.94), AppColors.teal.withValues(alpha: 0.2)],
                stops: const [0.42, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18).copyWith(top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    offer.tag.toUpperCase(),
                    style: AppText.sans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.serif(fontSize: 25, color: AppColors.cream),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.sub,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cream.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: onClaim,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              child: Text(
                                'Claim',
                                style: AppText.sans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
