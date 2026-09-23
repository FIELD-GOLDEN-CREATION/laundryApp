import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../utils/cart_math.dart';
import '../../../../utils/contact_launcher.dart';
import '../../../../models/service_package.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../widgets/remote_image.dart';

/// One bundled offer on the Shop Detail page. Shares the price-list row's
/// shell (white fill, `creamDark` hairline, radius 18, 40x40 `tealMuted`
/// leading tile) so packages read as part of the same menu rather than an
/// advert bolted on above it.
class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    required this.inBasket,
    required this.onSelect,
    this.shopPhone = '',
    this.shopName = '',
  });

  final ServicePackage package;

  /// Whether this package is already a line in the basket — the CTA flips
  /// to a "view it" affordance instead of adding a duplicate.
  final bool inBasket;

  final VoidCallback onSelect;

  /// Vendor phone for the WhatsApp enquiry button (hidden when empty).
  final String shopPhone;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    final savings = package.savingsPercent;
    final inclusions = package.inclusions.take(kMaxPackageInclusions).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: RemoteImage(
                  url: package.displayImage,
                  fallback: package.name,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      package.tagline,
                      style: AppText.sans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: AppColors.clientSecondaryText(context),
                      ),
                    ),
                    if (_scopeLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _scopeLabel,
                        style: AppText.sans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clientTealText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (package.tag.isNotEmpty) ...[
                const SizedBox(width: 8),
                _Pill(label: package.tag, bg: AppColors.clientPillAmber(context), fg: AppColors.clientAmberText(context)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // A Wrap, not a Row: price + unit + was-price + savings pill is
          // more than a narrow phone fits on one line, and this section is
          // worth a second line rather than an ellipsis through the price.
          Wrap(
            spacing: 8,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    package.priceNegotiable ? 'Negotiable' : formatMoney(package.priceTzs),
                    style: AppText.serif(fontSize: 20, color: AppColors.clientTealText(context)),
                  ),
                  if (!package.priceNegotiable) ...[
                    const SizedBox(width: 5),
                    Text(
                      package.priceUnit,
                      style: AppText.sans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.clientSecondaryText(context),
                      ),
                    ),
                  ],
                ],
              ),
              if (savings != null) ...[
                Text(
                  formatMoney(package.compareAtTzs!),
                  style: AppText.sans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.clientSecondaryText(context),
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
                _Pill(label: 'Save $savings%', bg: AppColors.clientPillTeal(context), fg: AppColors.clientTealText(context)),
              ],
            ],
          ),
          const SizedBox(height: 11),
          for (final line in inclusions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: AppIcon(AppIcons.checkCircle, size: 13, color: AppColors.clientTealText(context)),
                  ),                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppColors.clientSecondaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (package.note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              package.note.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.eyebrow(color: AppColors.clientSecondaryText(context)),
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: inBasket ? AppColors.clientPillTeal(context) : AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onSelect,
                      child: Center(
                        child: Text(
                          inBasket ? 'In basket · view' : 'Select package',
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: inBasket ? AppColors.clientTealText(context) : AppColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (shopPhone.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _chatWhatsApp(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.chat_rounded, size: 19, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One-line scope summary: weight, room count/garden, or item count.
  String get _scopeLabel {
    switch (package.kind) {
      case PackageKind.weight:
        final kg = package.weightKg;
        return kg != null
            ? 'Up to ${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg'
            : '';
      case PackageKind.itemCount:
        return '';
      case PackageKind.household:
        final parts = [
          if (package.rooms != null)
            '${package.rooms} room${package.rooms == 1 ? '' : 's'}',
          if (package.gardenYard) 'Garden',
        ];
        return parts.join(' · ');
    }
  }

  Future<void> _chatWhatsApp(BuildContext context) async {
    final ok = await launchWhatsAppChat(
      shopPhone,
      message: packageWhatsAppMessage(
        shopName: shopName.isEmpty ? 'there' : shopName,
        packageName: package.name,
        priceLabel: package.priceNegotiable
            ? 'Negotiable'
            : '${formatMoney(package.priceTzs)} ${package.priceUnit}',
        detail: _scopeLabel.isEmpty ? package.tagline : _scopeLabel,
      ),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }
}

/// Same rounded tag pill as the shop's feature badges, kept local so the
/// card can be dropped anywhere without dragging the screen's privates.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
