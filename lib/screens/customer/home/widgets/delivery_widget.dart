import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

class DeliveryWidget extends ConsumerWidget {
  const DeliveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language == 'Swahili' ? 'Jinsi Inavyofanya Kazi' : 'How It Works',
            style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DeliveryStep(
                icon: AppIcons.stepPickup,
                title: language == 'Swahili' ? 'Chukua' : 'Pickup',
                subtitle: language == 'Swahili' ? 'Tunachukua' : 'We collect',
                color: AppColors.teal,
              ),
              _DeliveryArrow(),
              _DeliveryStep(
                icon: AppIcons.serviceWashFold,
                title: language == 'Swahili' ? 'Osha' : 'Wash',
                subtitle: language == 'Swahili' ? 'Tunaosha' : 'We clean',
                color: AppColors.amber,
              ),
              _DeliveryArrow(),
              _DeliveryStep(
                icon: AppIcons.stepDeliver,
                title: language == 'Swahili' ? 'Leta' : 'Deliver',
                subtitle: language == 'Swahili' ? 'Tunaleta' : 'We return',
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tealMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.infoCircle, size: 20, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    language == 'Swahili'
                        ? 'Baada ya kuthibitisha oda yako, dereva wetu atachukua na kuleta nguo zako'
                        : 'After confirming your order, our driver will pick up and deliver your clothes',
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
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

class _DeliveryStep extends StatelessWidget {
  const _DeliveryStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: AppIcon(icon, size: 24, color: color)),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
        ),
      ],
    );
  }
}

class _DeliveryArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppIcon(
      AppIcons.arrowRight,
      color: AppColors.clientSecondaryText(context),
      size: 20,
    );
  }
}
