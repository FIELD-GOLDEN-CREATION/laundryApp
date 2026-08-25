import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/review_item.dart';
import '../../../../state/catalog_state.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

class ReviewsWidget extends ConsumerStatefulWidget {
  const ReviewsWidget({super.key});

  @override
  ConsumerState<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends ConsumerState<ReviewsWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reviewsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final reviews = ref.watch(reviewsProvider).items;

    if (reviews.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _ReviewCard(review: reviews[i], language: language),
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
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Column(
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
                    const SizedBox(height: 2),
                    Text(
                      review.stars,
                      style: AppText.sans(fontSize: 12, color: AppColors.amber),
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
    );
  }
}
