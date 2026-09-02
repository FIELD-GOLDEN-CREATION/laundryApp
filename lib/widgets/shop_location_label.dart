import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../utils/location.dart';

/// Renders a shop's address text, but if that text is a raw coordinate pair
/// (a location saved before reverse geocoding was reliable — see
/// `schedule_screen.dart`'s "Locate me" flow) it resolves a real place name
/// from the shop's lat/lng instead of showing GPS numbers to the customer.
class ShopLocationLabel extends StatelessWidget {
  const ShopLocationLabel({
    super.key,
    required this.shop,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  final Shop shop;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final raw = shop.meta;
    if (!looksLikeCoordinates(raw)) {
      return Text(raw, maxLines: maxLines, overflow: overflow, style: style);
    }
    final lat = shop.latitude;
    final lng = shop.longitude;
    if (lat == null || lng == null) {
      return Text('', maxLines: maxLines, overflow: overflow, style: style);
    }
    return FutureBuilder<String>(
      future: cachedAddressFromCoordinates(lat, lng),
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? '';
        return Text(resolved, maxLines: maxLines, overflow: overflow, style: style);
      },
    );
  }
}
