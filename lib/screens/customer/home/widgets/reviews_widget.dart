import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../data/vendor_mock_data.dart';
import '../../../../models/review_item.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

class ReviewsWidget extends ConsumerWidget {
  const ReviewsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        itemCount: kReviews.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _ReviewCard(review: kReviews[i], language: language),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.language});

  final ReviewItem review;
  final String language;

  @override
  Widget build(BuildContext context) {
    final filledStars = review.stars.split('').where((c) => c == '★').length;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -2,
            right: -2,
            child: AppIcon(AppIcons.quoteMark, size: 26, color: AppColors.clientBorder(context)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.tealMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        review.name[0],
                        style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.name,
                          style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++) ...[
                              AppIcon(i < filledStars ? AppIcons.star : AppIcons.starOutline, size: 11),
                              if (i < 4) const SizedBox(width: 2),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  review.text,
                  style: AppText.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.clientSecondaryText(context),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
