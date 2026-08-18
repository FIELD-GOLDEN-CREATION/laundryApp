import 'dart:async';

import 'package:flutter/material.dart';

import 'placeholder_image.dart';

/// Auto-advancing slideshow of a vendor's shop photos (4s per photo), shown
/// on the customer-facing Shop Detail hero in place of the single static
/// image when the vendor has uploaded shop photos via Vendor Settings.
class ShopPhotoSlideshow extends StatefulWidget {
  const ShopPhotoSlideshow({super.key, required this.labels});

  final List<String> labels;

  @override
  State<ShopPhotoSlideshow> createState() => _ShopPhotoSlideshowState();
}

class _ShopPhotoSlideshowState extends State<ShopPhotoSlideshow> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.labels.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        final next = (_index + 1) % widget.labels.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.labels.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => PlaceholderImage(label: widget.labels[i]),
        ),
        if (widget.labels.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == _index ? 0.95 : 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
