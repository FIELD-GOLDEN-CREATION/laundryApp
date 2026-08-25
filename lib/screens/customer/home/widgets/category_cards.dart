import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/laundry_category.dart';
import '../../../../state/catalog_state.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';
import '../../../../widgets/remote_image.dart';

class CategoryCardsWidget extends ConsumerStatefulWidget {
  const CategoryCardsWidget({super.key, required this.onCategoryTap});

  final ValueChanged<LaundryCategory> onCategoryTap;

  @override
  ConsumerState<CategoryCardsWidget> createState() => _CategoryCardsWidgetState();
}

class _CategoryCardsWidgetState extends ConsumerState<CategoryCardsWidget> {
  @override
  void initState() {
    super.initState();
    // Items are needed for the card's photo slideshow and item count.
    Future.microtask(
      () => ref.read(categoriesProvider.notifier).load(withItems: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final categories = ref.watch(categoriesProvider).items;
    final visible = categories.take(5).toList();

    if (visible.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _CategoryCard(
          category: visible[i],
          language: language,
          onTap: () => widget.onCategoryTap(visible[i]),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.language,
    required this.onTap,
  });

  final LaundryCategory category;
  final String language;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  final _controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        final next = (_currentIndex + 1) % widget.category.items.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final language = widget.language;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.clientSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.clientBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: category.items.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: RemoteImage(
                        url: category.items[i].imageUrl,
                        fallback: category.items[i].name,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${category.items.length} ${language == 'Swahili' ? 'bidhaa' : 'items'}',
                        style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  if (category.items.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < category.items.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: i == _currentIndex ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: i == _currentIndex ? 0.95 : 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language == 'Swahili' ? category.nameSwahili : category.name,
                    style: AppText.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.clientText(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    language == 'Swahili' ? 'Tazama zaidi' : 'View items',
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
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
