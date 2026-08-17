import 'package:flutter/material.dart';

import '../../data/promo_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StaffPromosScreen extends StatelessWidget {
  const StaffPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activePromos = kPromoOffers.where((p) => p.isActive && !p.isExpired).toList();
    final expiredPromos = kPromoOffers.where((p) => p.isExpired || !p.isActive).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Promos', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 8),
            Text(
              'View active promotions across all vendors.',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (activePromos.isNotEmpty) ...[
              Text('ACTIVE PROMOS', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              for (final promo in activePromos) ...[
                _PromoCard(promo: promo),
                const SizedBox(height: 10),
              ],
            ],
            if (expiredPromos.isNotEmpty) ...[
              Text('EXPIRED', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              for (final promo in expiredPromos) ...[
                _PromoCard(promo: promo, expired: true),
                const SizedBox(height: 10),
              ],
            ],
            if (activePromos.isEmpty && expiredPromos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: AppColors.muted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No promos available', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, this.expired = false});

  final dynamic promo;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        border: Border.all(color: expired ? AppColors.creamDark.withValues(alpha: 0.5) : AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: expired ? AppColors.creamDark : AppColors.tealMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.discountLabel,
                  style: AppText.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: expired ? AppColors.muted : AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                promo.code,
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(promo.title, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text(
            promo.description,
            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                promo.isExpired ? 'Expired' : promo.countdownLabel,
                style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(width: 16),
              Icon(Icons.redeem_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${promo.currentRedemptions} used',
                style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
