import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/widgets/sliver_clip_under_header.dart';

// Transparent pinned + floating header holding a search row in `bottom` (the
// Packages / Search layout), over a list of solid-colour cards. Only the
// `bottom` row is drawn — no flexible-space background — so the transparent
// gaps around the search pill are real gaps that content can show through.
const _bg = Color(0xFF080D12);
const _card = Color(0xFFE91E63);
const _statusInset = 47.0;

final _taps = <int>[];
final _boundary = GlobalKey();
final _pill = GlobalKey();

Widget _app({required bool clip}) {
  final content = SliverMainAxisGroup(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: 12,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _taps.add(i),
            child: const SizedBox(height: 300, child: ColoredBox(color: _card)),
          ),
        ),
      ),
    ],
  );

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RepaintBoundary(
      key: _boundary,
      child: ColoredBox(
        color: _bg,
        child: SafeArea(
          child: CustomScrollView(
            key: const Key('scroll'),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                primary: false,
                toolbarHeight: 0,
                expandedHeight: 190,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(54),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Container(
                      key: _pill,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              if (clip) SliverClipUnderHeader(sliver: content) else content,
            ],
          ),
        ),
      ),
    ),
  );
}

class _BareHeader extends SliverPersistentHeaderDelegate {
  _BareHeader(this.extent);

  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: extent);

  @override
  bool shouldRebuild(_BareHeader old) => old.extent != extent;
}

void _setUp(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  t.view.padding = const FakeViewPadding(top: _statusInset);
  t.view.viewPadding = const FakeViewPadding(top: _statusInset);
  addTearDown(t.view.reset);
}

Future<Color> _pixelAt(WidgetTester t, Offset p) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final color = await t.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    final i = ((p.dy.round() * image.width) + p.dx.round()) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  });
  return color!;
}

Future<void> _collapse(WidgetTester t) async {
  await t.drag(find.byKey(const Key('scroll')), const Offset(0, -500));
  await t.pumpAndSettle();
}

void main() {
  setUp(_taps.clear);

  // The header's bottom edge (search pill + its 8px bottom padding) and a
  // point in the transparent gap just under the pill, inside the header.
  Offset gapUnderPill(WidgetTester t) {
    final r = t.getRect(find.byKey(_pill));
    return Offset(r.left + 40, r.bottom + 4);
  }

  testWidgets('control: without the clip, cards show around the search pill', (
    t,
  ) async {
    _setUp(t);
    await t.pumpWidget(_app(clip: false));
    await _collapse(t);

    expect(await _pixelAt(t, gapUnderPill(t)), _card);
  });

  testWidgets('clip: nothing paints behind the search pill', (t) async {
    _setUp(t);
    await t.pumpWidget(_app(clip: true));
    await _collapse(t);

    final gap = gapUnderPill(t);
    expect(await _pixelAt(t, gap), _bg);

    // Just below the header edge the list is still visible and tappable.
    final below = Offset(gap.dx, t.getRect(find.byKey(_pill)).bottom + 12);
    expect(await _pixelAt(t, below), _card);
    await t.tapAt(below);
    expect(_taps, isNotEmpty);
  });

  testWidgets('clip follows the header when snap re-expands it', (t) async {
    _setUp(t);
    await t.pumpWidget(_app(clip: true));
    await _collapse(t);
    // Scrolling up floats the header back open (snap), pushing the pill down.
    await t.drag(find.byKey(const Key('scroll')), const Offset(0, 60));
    await t.pumpAndSettle();

    final gap = gapUnderPill(t);
    expect(gap.dy, greaterThan(_statusInset + 54 + 4));
    expect(await _pixelAt(t, gap), _bg);
  });

  // AppBar absorbs taps in its own bounds, so use a bare pinned header (a
  // SizedBox, nothing hit-testable) to show the clip also blocks taps.
  for (final clip in [false, true]) {
    testWidgets('clip=$clip: taps under a bare pinned header', (t) async {
      _setUp(t);
      const headerH = 54.0;
      final content = SliverList.builder(
        itemCount: 12,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _taps.add(i),
          child: const SizedBox(height: 300, child: ColoredBox(color: _card)),
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          home: SafeArea(
            child: CustomScrollView(
              key: const Key('scroll'),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _BareHeader(headerH),
                ),
                if (clip) SliverClipUnderHeader(sliver: content) else content,
              ],
            ),
          ),
        ),
      );
      await t.drag(find.byKey(const Key('scroll')), const Offset(0, -400));
      await t.pumpAndSettle();

      await t.tapAt(const Offset(200, _statusInset + headerH / 2));
      expect(_taps.isNotEmpty, !clip);

      // Below the header edge the list is always tappable.
      _taps.clear();
      await t.tapAt(const Offset(200, _statusInset + headerH + 20));
      expect(_taps, isNotEmpty);
    });
  }

  testWidgets('no clip while the header is fully expanded', (t) async {
    _setUp(t);
    await t.pumpWidget(_app(clip: true));

    // First card starts right under the expanded header, unclipped.
    final justBelow = Offset(200, _statusInset + 190 + 6);
    expect(await _pixelAt(t, justBelow), _card);
  });
}
