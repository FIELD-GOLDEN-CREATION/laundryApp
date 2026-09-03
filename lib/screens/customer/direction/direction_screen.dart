import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../models/shop.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/profile_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/round_back_button.dart';

class DirectionScreen extends ConsumerStatefulWidget {
  const DirectionScreen({super.key, required this.shop});

  final Shop shop;

  @override
  ConsumerState<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends ConsumerState<DirectionScreen> {
  ll.LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
  }

  void _loadMyLocation() {
    final addresses = ref.read(profileProvider).addresses;
    for (final a in addresses) {
      if (a.latitude != null && a.longitude != null) {
        _myLocation = ll.LatLng(a.latitude!, a.longitude!);
        setState(() {});
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final language = ref.watch(clientPreferencesProvider).language;

    final shopLatLng = (shop.latitude != null && shop.longitude != null)
        ? ll.LatLng(shop.latitude!, shop.longitude!)
        : null;

    final points = <ll.LatLng>[
      if (shopLatLng != null) shopLatLng,
      if (_myLocation != null) _myLocation!,
    ];

    final center = points.isNotEmpty
        ? points.reduce((a, b) => ll.LatLng(
            (a.latitude + b.latitude) / 2,
            (a.longitude + b.longitude) / 2,
          ))
        : const ll.LatLng(-6.7924, 39.2083);

    final zoom = points.length == 2 ? 13.0 : 15.0;

    return Scaffold(
      backgroundColor: AppColors.clientSurface(context),
      body: Stack(
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
                if (shopLatLng != null)
                  Marker(
                    point: shopLatLng,
                    width: 40,
                    height: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.teal, blurRadius: 10, spreadRadius: 3)],
                          ),
                          child: const Icon(Icons.store, color: Colors.white, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.clientSurface(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.clientBorder(context)),
                          ),
                          child: Text(shop.name, style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                if (_myLocation != null)
                  Marker(
                    point: _myLocation!,
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
              if (shopLatLng != null && _myLocation != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [_myLocation!, shopLatLng],
                    color: AppColors.teal.withValues(alpha: 0.6),
                    strokeWidth: 3,
                  ),
                ]),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundBackButton(onPressed: () => context.pop()),
                    _GlassButton(
                      icon: Icons.my_location,
                      onTap: _loadMyLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DirectionBottomSheet(
              shop: shop,
              language: language,
              onNavigate: _openGoogleMaps,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final shop = widget.shop;
    final shopLat = shop.latitude;
    final shopLng = shop.longitude;
    if (shopLat == null || shopLng == null) return;

    final myLat = _myLocation?.latitude;
    final myLng = _myLocation?.longitude;

    final String url;
    if (myLat != null && myLng != null) {
      url = 'https://www.google.com/maps/dir/?api=1&origin=$myLat,$myLng&destination=$shopLat,$shopLng&travelmode=driving';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=$shopLat,$shopLng';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.clientSurface(context).withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.clientBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: Icon(icon, size: 20, color: AppColors.clientText(context))),
        ),
      ),
    );
  }
}

class _DirectionBottomSheet extends StatelessWidget {
  const _DirectionBottomSheet({required this.shop, required this.language, required this.onNavigate});

  final Shop shop;
  final String language;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final distKm = shop.distanceKm;
    final estMin = (distKm * 3).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.clientBorder(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.clientBorder(context), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(shop.name, style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
          const SizedBox(height: 6),
          Text(
            shop.distance,
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DirectionStep(
                icon: Icons.straighten,
                label: '${distKm.toStringAsFixed(1)} km',
                sublabel: language == 'Swahili' ? 'Umbali' : 'Distance',
                color: AppColors.teal,
              ),
              const SizedBox(width: 20),
              _DirectionStep(
                icon: Icons.schedule,
                label: '$estMin min',
                sublabel: language == 'Swahili' ? 'Muda' : 'Est. time',
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onNavigate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      language == 'Swahili' ? 'Fungua Google Maps' : 'Open in Google Maps',
                      style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionStep extends StatelessWidget {
  const _DirectionStep({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
            Text(sublabel, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
          ],
        ),
      ],
    );
  }
}
