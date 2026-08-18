import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/basket_helper.dart';
import '../state/cart_state.dart';
import '../state/fulfillment_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Call before adding anything to the basket. Returns true once the basket
/// is safely pointed at [shop] — either it already was, or it was empty, or
/// the customer agreed to start a fresh one.
///
/// Returns false if they backed out, in which case the caller must not add
/// the item and must not navigate.
Future<bool> ensureBasketShop(BuildContext context, WidgetRef ref, String shop) async {
  final fulfillment = ref.read(fulfillmentProvider);
  if (!basketBelongsToOtherShop(ref.read(cartProvider), fulfillment, shop)) {
    // Nothing at stake — claim the empty basket for this vendor so the cart
    // banner, chat thread and placed order all name the right shop.
    if (fulfillment.shop != shop) ref.read(fulfillmentProvider.notifier).startBasketFor(shop);
    return true;
  }

  final confirmed = await showSwitchBasketSheet(context, currentShop: fulfillment.shop, newShop: shop);
  if (!confirmed) return false;

  ref.read(cartProvider.notifier).clear();
  ref.read(fulfillmentProvider.notifier).startBasketFor(shop);
  return true;
}

/// The "your basket has items from another shop" confirmation. Styled after
/// `showCrudFormModal` — cream sheet, grabber, Cancel + primary pair.
Future<bool> showSwitchBasketSheet(
  BuildContext context, {
  required String currentShop,
  required String newShop,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.shopping_bag_outlined, size: 21, color: AppColors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Start a new basket?', style: AppText.serif(fontSize: 21))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your basket has items from $currentShop. One order goes to one '
            'shop, so ordering from $newShop will empty it first.',
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(false),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        'Keep basket',
                        style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Material(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(sheetContext).pop(true),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        'Start new basket',
                        style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
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
  return result ?? false;
}
