import 'package:flutter/material.dart';

import 'placeholder_image.dart';

/// A network image that degrades gracefully: shows the existing styled
/// placeholder while loading and whenever the URL can't be fetched or
/// decoded (the seed data uses Unsplash *page* links, which aren't image
/// files — swap them for direct `images.unsplash.com/photo-...` URLs and the
/// real photos render here with zero code changes).
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.fallback,
    this.borderRadius = 0,
    this.circle = false,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String url;
  final String fallback;
  final double borderRadius;
  final bool circle;
  final BoxFit fit;

  /// Overrides the default text placeholder (used where a labelled box would
  /// show through — e.g. offer cards keep a plain decorative fill instead).
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final placeholderWidget = placeholder ?? PlaceholderImage(label: fallback, borderRadius: borderRadius, circle: circle);
    if (url.isEmpty) return placeholderWidget;

    final image = Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => placeholderWidget,
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholderWidget,
    );

    if (circle) return ClipOval(child: image);
    return ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: image);
  }
}
