import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../state/auth_state.dart';
import '../../../../state/client_preferences_state.dart';
import '../../../../state/platform_stats_state.dart';
import '../../../../models/user_role.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../utils/cart_math.dart';

class VendorBannerWidget extends ConsumerWidget {
  const VendorBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    final isGuest = ref.watch(authProvider.select((s) => s.role == UserRole.guest));
    final stats = ref.watch(platformStatsProvider).valueOrNull;

    // Don't show to guests — they haven't even signed up yet
    if (isGuest) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5C58), Color(0xFF2A7D78), Color(0xFF1A5C58)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.store_rounded, size: 20, color: AppColors.cream),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        language == 'Swahili'
                            ? 'FreshFold kwa Wauzaji'
                            : 'FreshFold for Vendors',
                        style: AppText.sans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  language == 'Swahili'
                      ? 'Jiunge na wauzaji wanaopata mapato kupitia FreshFold. Viwango vya juu, malipo ya haraka, na msaada wa moja kwa moja.'
                      : 'Join the vendors earning through FreshFold. Top-rated service, fast payouts, and dedicated support.',
                  style: AppText.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      label: language == 'Swahili' ? 'Wauzaji' : 'Vendors',
                      value: stats != null && stats.vendorCount > 0 ? '${stats.vendorCount}+' : '—',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: language == 'Swahili' ? 'Mapato/Mwezi' : 'Earnings/Mo',
                      value: stats != null ? formatMoney(stats.monthlyEarningsTzs.toDouble()) : '—',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: language == 'Swahili' ? 'Ukadiriaji' : 'Rating',
                      value: stats?.avgRating != null ? '${stats!.avgRating!.toStringAsFixed(1)} ★' : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/profile/apply-vendor'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          language == 'Swahili' ? 'Jifunze zaidi' : 'Learn more',
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.cream.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.sans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.cream.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
