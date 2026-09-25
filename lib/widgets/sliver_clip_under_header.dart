import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Keeps [sliver] from painting or receiving taps underneath a pinned /
/// floating header (e.g. a transparent `SliverAppBar` holding a search bar)
/// that sits above it in the same `CustomScrollView`.
///
/// A transparent header lets scrolled content show through around it. This
/// clips the sliver at the header's bottom edge instead. The edge comes from
/// `SliverConstraints.overlap` — how far earlier slivers are painted over this
/// one — so it tracks the header through collapse, float and snap with no
/// scroll listeners, and is zero (no clip at all) while the header is fully
/// expanded. Content still runs edge to edge everywhere else, e.g. behind the
/// floating bottom nav.
///
/// Wrap several content slivers in a `SliverMainAxisGroup` to clip them
/// together. Only top-down vertical scrolling is clipped; any other axis is
/// painted unchanged.
class SliverClipUnderHeader extends SingleChildRenderObjectWidget {
  const SliverClipUnderHeader({super.key, required Widget sliver})
    : super(child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverClipUnderHeader();
}

class _RenderSliverClipUnderHeader extends RenderProxySliver {
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();

  double get _clipTop {
    final c = constraints;
    if (c.axisDirection != AxisDirection.down ||
        c.growthDirection != GrowthDirection.forward) {
      return 0;
    }
    return c.overlap > 0 ? c.overlap : 0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || !child.geometry!.visible) {
      _clipLayer.layer = null;
      return;
    }
    final clipTop = _clipTop;
    if (clipTop <= 0) {
      _clipLayer.layer = null;
      context.paintChild(child, offset);
      return;
    }
    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTRB(
        0,
        clipTop,
        constraints.crossAxisExtent,
        geometry!.paintExtent,
      ),
      (context, offset) => context.paintChild(child, offset),
      oldLayer: _clipLayer.layer,
    );
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (mainAxisPosition < _clipTop) return false;
    return super.hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    super.dispose();
  }
}
