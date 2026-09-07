import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

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
                  shopLat: shopProfile.latitude,
                  shopLng: shopProfile.longitude,
                  clientLat: state.deliveryLat,
                  clientLng: state.deliveryLng,
                  label: state.deliveryAddress.isEmpty ? 'Delivery address' : state.deliveryAddress,
                ),
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
    required this.shopLat,
    required this.shopLng,
    required this.clientLat,
    required this.clientLng,
    required this.label,
  });

  final double? shopLat;
  final double? shopLng;
  final double? clientLat;
  final double? clientLng;
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
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.teal, blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 18),
                      ),
                    ),
                  if (clientLat != null && clientLng != null)
                    Marker(
                      point: ll.LatLng(clientLat!, clientLng!),
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.person, color: AppColors.teal, size: 16),
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
