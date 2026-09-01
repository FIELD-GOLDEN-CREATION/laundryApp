import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/promo_offer.dart';
import '../../../../models/shop.dart';
import '../../../../state/catalog_state.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../widgets/remote_image.dart';

class OfferCard extends ConsumerStatefulWidget {
  const OfferCard({super.key, required this.offer});

  final PromoOffer offer;

  @override
  ConsumerState<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<OfferCard> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.offer.timeRemaining;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final r = widget.offer.timeRemaining;
      setState(() => _remaining = r);
      if (r.inSeconds <= 0) _timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _countdownText() {
    if (_remaining.inSeconds <= 0) return 'Expired';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m left';
    return '${m}m left';
  }

  /// The offer's vendor, resolved from the already-loaded shop list by id —
  /// null when that shop isn't in the current list (e.g. still loading).
  Shop? _resolveShop() {
    final vendorId = widget.offer.vendorId;
    if (vendorId == null || vendorId.isEmpty) return null;
    final shops = ref.read(shopsProvider).items;
    for (final s in shops) {
      if (s.slotId == vendorId) return s;
    }
    return null;
  }

  void _showPromoPopup() {
    final shop = _resolveShop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PromoPopupSheet(
        offer: widget.offer,
        onShopNow: shop == null ? null : () => context.push('/detail', extra: shop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPromoPopup,
      child: Container(
        width: 296,
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(22)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF2A7D78)),
            RemoteImage(url: widget.offer.imageUrl, fallback: '', placeholder: const SizedBox.shrink()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.teal.withValues(alpha: 0.94), AppColors.teal.withValues(alpha: 0.2)],
                  stops: const [0.42, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18).copyWith(top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          widget.offer.discountLabel.toUpperCase(),
                          style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.amber, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _remaining.inSeconds > 0 ? AppColors.danger.withValues(alpha: 0.15) : AppColors.muted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 10,
                              color: _remaining.inSeconds > 0 ? AppColors.danger : AppColors.muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _countdownText(),
                              style: AppText.sans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _remaining.inSeconds > 0 ? AppColors.danger : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.offer.vendorName.isNotEmpty) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_rounded, size: 12, color: AppColors.cream.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              widget.offer.vendorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      SizedBox(
                        width: 170,
                        child: Text(
                          widget.offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.serif(fontSize: 25, color: AppColors.cream),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.offer.description,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.72)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _showPromoPopup,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                child: Text(
                                  'Claim',
                                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _PromoPopupSheet extends StatelessWidget {
  const _PromoPopupSheet({required this.offer, this.onShopNow});

  final PromoOffer offer;

  /// Opens the offer's vendor shop page; null when the vendor couldn't be
  /// resolved from the currently loaded shop list.
  final VoidCallback? onShopNow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.local_offer_rounded, color: AppColors.teal, size: 24),
              ),
              const SizedBox(height: 12),
              if (offer.vendorName.isNotEmpty) ...[
                Text(
                  'Valid at ${offer.vendorName}',
                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
              ],
              Text(offer.title, style: AppText.serif(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                offer.description,
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.teal, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  offer.code,
                  style: AppText.sans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              if (offer.minSpend > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Min spend: TZS ${offer.minSpend.round()}',
                  style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: offer.code));
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code "${offer.code}" copied!', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700)),
                              backgroundColor: AppColors.teal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          child: Text(
                            'Copy Code',
                            style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.creamDark,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        width: 46,
                        alignment: Alignment.center,
                        child: Icon(Icons.close, color: AppColors.muted, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              if (onShopNow != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context);
                        onShopNow!();
                      },
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Shop now',
                          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
