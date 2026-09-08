import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

/// "How It Works" on the customer home page.
///
/// No delivery in this business model: we assure the order, connect the
/// customer with a professional vendor around their area, and map the
/// location of nearby vendors so they can pick one.
class DeliveryWidget extends ConsumerWidget {
  const DeliveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    final isSw = language == 'Swahili';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A5C58),
            Color(0xFF134E4A),
            Color(0xFF0B2E33),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glows — amber warmth + soft white rings so the
          // card pops against the long white stretch of the home feed.
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -60,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFF6C453),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSw ? 'HATUA 3 RAHISI' : '3 EASY STEPS',
                            style: AppText.sans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF6C453),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isSw ? 'Jinsi Inavyofanya Kazi' : 'How It Works',
                  style: AppText.sans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSw
                      ? 'Tunathibitisha oda yako na kukunganisha na fundi karibu nawe'
                      : 'We assure your order and link you to pros around you',
                  style: AppText.sans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HowStep(
                        number: '1',
                        icon: Icons.verified_outlined,
                        title: isSw ? 'Thibitisha' : 'Assured',
                        subtitle: isSw ? 'Oda yako salama' : 'We assure order',
                      ),
                    ),
                    const _StepConnector(),
                    Expanded(
                      child: _HowStep(
                        number: '2',
                        icon: Icons.handshake_outlined,
                        title: isSw ? 'Unganisha' : 'Matched',
                        subtitle:
                            isSw ? 'Fundi karibu nawe' : 'Pro vendor near you',
                      ),
                    ),
                    const _StepConnector(),
                    Expanded(
                      child: _HowStep(
                        number: '3',
                        icon: Icons.map_outlined,
                        title: isSw ? 'Ramani' : 'Locate',
                        subtitle:
                            isSw ? 'Chagua dukani' : 'Pick on the map',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFF6C453),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isSw
                              ? 'Ukithibitisha, tunaunganisha na duka la kitaalamu lililo karibu — lichague kwenye ramani ukalete nguo.'
                              : 'Once you confirm, we connect you to a professional vendor around you — pick them on the map and drop off your laundry.',
                          style: AppText.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
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

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.teal, size: 26),
            ),
            Positioned(
              right: -4,
              top: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4841A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: AppText.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.sans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.sans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Container(
            width: 12,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
