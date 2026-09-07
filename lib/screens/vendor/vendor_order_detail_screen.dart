import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../state/vendor_order_detail_state.dart';
import '../../state/vendor_orders_state.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../utils/time_format.dart';
import '../../widgets/round_back_button.dart';

class VendorOrderDetailScreen extends ConsumerStatefulWidget {
  const VendorOrderDetailScreen({super.key});

  @override
  ConsumerState<VendorOrderDetailScreen> createState() => _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends ConsumerState<VendorOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Which order to show: the one tapped in the list, else the oldest
      // open one so deep links straight to the route still render data.
      final orders = ref.read(vendorOrdersProvider);
      final id = orders.selectedId ??
          (orders.wipOrders.isNotEmpty
              ? orders.wipOrders.first.id
              : orders.newOrders.isNotEmpty ? orders.newOrders.first.id : '');
      ref.read(vendorOrderDetailProvider.notifier).load(normalizeVendorOrderId(id));
      ref.read(vendorProfileProvider.notifier).loadProfile();
    });
  }

  void _showStatusError(String title) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorOrderDetailProvider);
    final notifier = ref.read(vendorOrderDetailProvider.notifier);
    final packageLines = state.packageLines;
    final itemLines = state.itemLines;
    final addons = state.addons;
    final bulkApplied = state.bulkSnapshot != null;
    final shopProfile = ref.watch(vendorProfileProvider);
    final showMap = state.isAccepted &&
        state.fulfillment == 'delivery' &&
        (shopProfile.latitude != null || state.deliveryLat != null);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Row(
              children: [
                RoundBackButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.hasOrder ? 'Order #LD-${state.orderId}' : 'Order',
                        style: AppText.serif(fontSize: 23),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (state.customerName.isNotEmpty) state.customerName,
                          if (state.itemsSummary.isNotEmpty) state.itemsSummary,
                        ].join(' · '),
                        style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              if (showMap) ...[
                const _SectionLabel('Delivery location'),
                _OrderMap(
                  shopName: shopProfile.shopTitle.isEmpty ? 'Your shop' : shopProfile.shopTitle,
                  shopLat: shopProfile.latitude,
                  shopLng: shopProfile.longitude,
                  clientLat: state.deliveryLat,
                  clientLng: state.deliveryLng,
                  clientTag: state.customerName.isEmpty ? 'Customer' : state.customerName,
                  label: state.deliveryAddress.isEmpty ? 'Delivery address' : state.deliveryAddress,
                ),
                const SizedBox(height: 12),
                if (shopProfile.latitude != null && shopProfile.longitude != null && state.deliveryLat != null && state.deliveryLng != null)
                  _RouteStats(
                    distanceKm: Geolocator.distanceBetween(
                          shopProfile.latitude!,
                          shopProfile.longitude!,
                          state.deliveryLat!,
                          state.deliveryLng!,
                        ) /
                        1000,
                  ),
                if (state.deliveryLat != null && state.deliveryLng != null) ...[
                  const SizedBox(height: 12),
                  _OpenInMapsButton(
                    onTap: () => _openGoogleMaps(
                      originLat: shopProfile.latitude,
                      originLng: shopProfile.longitude,
                      destLat: state.deliveryLat!,
                      destLng: state.deliveryLng!,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              // Only the sections the customer actually picked from render —
              // an empty package/add-ons/items card is just noise.
              if (packageLines.isNotEmpty) ...[
                const _SectionLabel('Package selected'),
                _LineItemsCard(lines: packageLines),
              ],
              if (addons.isNotEmpty) ...[
                const _SectionLabel('Add-on services selected'),
                _AddonsCard(addons: addons),
              ],
              if (itemLines.isNotEmpty) ...[
                const _SectionLabel('Categories & items'),
                _LineItemsCard(lines: itemLines, showCategory: true),
              ],
            ],
            const _SectionLabel('Processing status'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (final step in state.steps)
                    _ProcessStepRow(
                      step: step,
                      locked: kVendorLockedStatuses.contains(step.status),
                      onTap: state.isUpdatingStatus || kVendorLockedStatuses.contains(step.status)
                          ? null
                          : () async {
                              final ok = await notifier.toggleStep(step.status);
                              if (!ok) _showStatusError('Could not update status to "${step.title}"');
                            },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: bulkApplied ? AppColors.tealMuted : AppColors.teal,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: !state.hasOrder || state.isUpdatingStatus
                      ? null
                      : () async {
                          final ok = bulkApplied ? await notifier.undoMarkAllComplete() : await notifier.markAllComplete();
                          if (!ok) _showStatusError('Could not update processing status');
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        bulkApplied ? 'Undo mark all complete' : 'Mark all complete',
                        style: AppText.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: bulkApplied ? AppColors.teal : AppColors.cream,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A real OpenStreetMap preview showing this shop and the order's delivery
/// point — both with markers when coordinates are available. Mirrors the
/// customer app's `_OrderMap` in order_detail_screen.dart.
class _OrderMap extends StatelessWidget {
  const _OrderMap({
    required this.shopName,
    required this.shopLat,
    required this.shopLng,
    required this.clientLat,
    required this.clientLng,
    required this.clientTag,
    required this.label,
  });

  final String shopName;
  final double? shopLat;
  final double? shopLng;
  final double? clientLat;
  final double? clientLng;

  /// Short caption under the delivery-point pin (the customer's name).
  final String clientTag;
  final String label;

  @override
  Widget build(BuildContext context) {
    final points = <ll.LatLng>[];
    if (shopLat != null && shopLng != null) points.add(ll.LatLng(shopLat!, shopLng!));
    if (clientLat != null && clientLng != null) points.add(ll.LatLng(clientLat!, clientLng!));

    final center = points.isNotEmpty
        ? points.reduce((a, b) => ll.LatLng(
            (a.latitude + b.latitude) / 2,
            (a.longitude + b.longitude) / 2,
          ))
        : const ll.LatLng(-6.7924, 39.2083); // Dar es Salaam fallback

    final zoom = points.length == 2 ? 13.0 : 15.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.freshfold.laundry',
                ),
                MarkerLayer(markers: [
                  if (shopLat != null && shopLng != null)
                    Marker(
                      point: ll.LatLng(shopLat!, shopLng!),
                      width: 90,
                      height: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.teal, blurRadius: 8, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.store, color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 2),
                          _MarkerTag(text: shopName),
                        ],
                      ),
                    ),
                  if (clientLat != null && clientLng != null)
                    Marker(
                      point: ll.LatLng(clientLat!, clientLng!),
                      width: 70,
                      height: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.person, color: AppColors.teal, size: 16),
                          ),
                          const SizedBox(height: 2),
                          _MarkerTag(text: clientTag),
                        ],
                      ),
                    ),
                ]),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small name pill under a map marker's icon (the shop name or customer name).
class _MarkerTag extends StatelessWidget {
  const _MarkerTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Straight-line distance and a rough 3 min/km driving estimate between the
/// shop and the delivery point — mirrors the customer app's `_RouteStats`.
class _RouteStats extends StatelessWidget {
  const _RouteStats({required this.distanceKm});
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final estMin = (distanceKm * 3).round();
    return Row(
      children: [
        _RouteStat(icon: Icons.straighten, value: '${distanceKm.toStringAsFixed(1)} km', label: 'Distance'),
        const SizedBox(width: 20),
        _RouteStat(icon: Icons.schedule, value: '$estMin min', label: 'Est. time', color: AppColors.amber),
      ],
    );
  }
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({required this.icon, required this.value, required this.label, this.color = AppColors.teal});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
            Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ],
        ),
      ],
    );
  }
}

/// Opens turn-by-turn directions in Google Maps from the shop to the
/// delivery point — mirrors the customer app's direction screen, reversed
/// since the vendor is the one travelling to drop the order off.
Future<void> _openGoogleMaps({double? originLat, double? originLng, required double destLat, required double destLng}) async {
  final String url;
  if (originLat != null && originLng != null) {
    url = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
  } else {
    url = 'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng';
  }
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _OpenInMapsButton extends StatelessWidget {
  const _OpenInMapsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Open in Google Maps', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

/// Package or per-item basket lines — same row shape, optionally with a
/// category eyebrow above the name (used for "Categories & items").
class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({required this.lines, this.showCategory = false});

  final List<DetailLine> lines;
  final bool showCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: i == lines.length - 1 ? Colors.transparent : AppColors.cream),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: showCategory
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lines[i].categoryName.isNotEmpty) ...[
                                Text(
                                  lines[i].categoryName.toUpperCase(),
                                  style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.4),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                '${lines[i].qty}× ${lines[i].name}',
                                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : Text(
                            '${lines[i].qty}× ${lines[i].name}',
                            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                  ),
                  Text(
                    formatTzs(lines[i].total),
                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddonsCard extends StatelessWidget {
  const _AddonsCard({required this.addons});
  final List<DetailAddon> addons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < addons.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: i == addons.length - 1 ? Colors.transparent : AppColors.cream),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.tealMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      addons[i].title,
                      style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    formatTzs(addons[i].priceTzs),
                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.amber),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcessStepRow extends StatelessWidget {
  const _ProcessStepRow({required this.step, required this.locked, this.onTap});

  final VendorTrackStep step;

  /// Locked steps (order placed, accepted) are always-true facts of this
  /// screen being reachable at all — shown done, never tappable.
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = step.done || locked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.teal : Colors.white,
                  border: Border.all(color: done ? AppColors.teal : const Color(0xFFD7D2C6), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.cream : const Color(0xFFD7D2C6)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  step.title,
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: done ? AppColors.slate : AppColors.muted),
                ),
              ),
              Text(
                step.completedAt != null ? formatClockTime(step.completedAt!) : (locked ? '—' : 'Pending'),
                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
