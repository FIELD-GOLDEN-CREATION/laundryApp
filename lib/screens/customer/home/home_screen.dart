import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../data/mock_data.dart';
import '../../../data/promo_mock_data.dart';
import '../../../models/user_role.dart';
import '../../../state/auth_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/section_header.dart';
import 'widgets/active_order_banner.dart';
import 'widgets/offer_card.dart';
import 'widgets/category_cards.dart';
import 'widgets/delivery_widget.dart';
import 'widgets/reviews_widget.dart';
import 'widgets/shop_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider.select((s) => s.role == UserRole.guest));
    final language = ref.watch(clientPreferencesProvider).language;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                 isGuest: isGuest,
                 language: language,
                onProfile: () {
                  // Ports the source's `goProfile:()=>gate('profile', reason)`
                  // — always gated, unlike the tab bar's Profile tab which
                  // only gates for guests. Authed customers land on the
                  // Profile tab (a simplification of the source's literal
                  // stack-push there, same category of deliberate deviation
                  // as this app's StatefulShellRoute tab-stack choice).
                  if (gateGuest(ref, context, 'Log in to see your profile, addresses and saved shops.')) return;
                  context.go('/profile');
                },
                onNotifs: () => context.push('/notifs'),
                onSearch: () => context.push('/search'),
              ),
              const SizedBox(height: 14),
              // Guests have no orders yet, so there's nothing to track.
              if (!isGuest)
                ActiveOrderBanner(
                   title: clientLabel('Order #LD-2481 is being washed', 'Oda #LD-2481 inafuliwa', language),
                   subtitle: clientLabel('Back at your door by Thu, 6:00 PM', 'Itarudi mlangoni Alhamisi, saa 12:00 jioni', language),
                  onTap: () => context.push('/track'),
                ),
               SectionHeader(title: clientLabel('Just for you', 'Kwa ajili yako', language), seeAllLabel: clientLabel('See all', 'Tazama yote', language), onSeeAll: () => context.push('/search')),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                  itemCount: kPromoOffers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => OfferCard(
                    offer: kPromoOffers[i],
                    onClaim: () {
                      if (gateGuest(
                        ref,
                        context,
                        'Log in as a customer to claim this offer.',
                        redirectPath: '/detail',
                      )) {
                        return;
                      }
                      context.push('/detail');
                    },
                  ),
                ),
              ),
               SectionHeader(title: clientLabel('Categories', 'Kategoria', language)),
              CategoryCardsWidget(
                onCategoryTap: (category) {
                  if (gateGuest(
                    ref,
                    context,
                    'Log in as a customer to view ${category.name}.',
                    redirectPath: '/category-detail',
                    redirectExtra: category,
                  )) {
                    return;
                  }
                  context.push('/category-detail', extra: category);
                },
              ),
              const SizedBox(height: 12),
              const DeliveryWidget(),
              const SizedBox(height: 12),
              SectionHeader(title: clientLabel('What our customers say', 'Wateja wetu wanasema', language)),
              const ReviewsWidget(),
               SectionHeader(title: clientLabel('Nearby shops', 'Maduka yaliyo karibu', language), seeAllLabel: clientLabel('See all', 'Tazama yote', language), onSeeAll: () => context.push('/search')),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  itemCount: kShops.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => ShopCard(
                    shop: kShops[i],
                    onTap: () {
                      if (gateGuest(
                        ref,
                        context,
                        'Log in as a customer to view ${kShops[i].name}.',
                        redirectPath: '/detail',
                        redirectExtra: kShops[i],
                      )) {
                        return;
                      }
                      context.push('/detail', extra: kShops[i]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isGuest, required this.language, required this.onProfile, required this.onNotifs, required this.onSearch});

  final bool isGuest;
  final String language;
  final VoidCallback onProfile;
  final VoidCallback onNotifs;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        color: AppColors.teal,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: 20,
              top: 60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guests haven't set a pickup address and have no
                // notifications to check, so there's nothing in this row
                // for them at all.
                if (!isGuest)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: onProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                               clientLabel('PICKUP LOCATION', 'MAHALI PA KUCHUKUA', language),
                              style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const AppIcon(AppIcons.locationPin, size: 15),
                                const SizedBox(width: 7),
                                Text(
                                  '12 Chole Road, Masaki',
                                  style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                                ),
                                const SizedBox(width: 7),
                                AppIcon(AppIcons.chevronDownSmall, size: 11, color: AppColors.cream.withValues(alpha: 0.7)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _HeaderIconButton(icon: AppIcons.bell, badge: true, onTap: onNotifs),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onSearch,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const AppIcon(AppIcons.search, size: 17),
                            const SizedBox(width: 10),
                            Text(
                                   clientLabel('Search services or shops', 'Tafuta huduma au maduka', language),
                              style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  final String icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppIcon(icon, size: 18, color: AppColors.cream),
              if (badge)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: AppColors.teal, width: 2)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
