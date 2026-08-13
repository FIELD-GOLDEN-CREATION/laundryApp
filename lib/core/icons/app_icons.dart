import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bespoke stroke icons ported verbatim (same viewBox/paths) from the
/// Claude Design source. Each raw SVG carries a sensible baked-in color;
/// pass [AppIcon.color] to recolor it uniformly via a ColorFilter, which
/// covers every recolor case actually used in the source (e.g. tab bar
/// active/inactive, bell on teal vs on white).
class AppIcon extends StatelessWidget {
  const AppIcon(this._svg, {super.key, this.size = 20, this.color});

  final String _svg;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

abstract final class AppIcons {
  static const backChevron =
      '<svg width="9" height="14" viewBox="0 0 9 14" fill="none" stroke="#2c3e50" stroke-width="2" stroke-linecap="round"><path d="M7.5 1.5l-5.5 5.5 5.5 5.5"/></svg>';

  static const chevronRightSmall =
      '<svg width="8" height="13" viewBox="0 0 8 13" fill="none" stroke="#1a5c58" stroke-width="2" stroke-linecap="round"><path d="M1.5 1.5L6.5 6.5l-5 5"/></svg>';

  static const chevronDownSmall =
      '<svg width="11" height="7" viewBox="0 0 11 7" fill="none" stroke="#f5f0e8" stroke-width="1.8" stroke-linecap="round"><path d="M1 1l4.5 4.5L10 1"/></svg>';

  static const locationPin =
      '<svg width="15" height="18" viewBox="0 0 15 18" fill="none" stroke="#d4841a" stroke-width="1.8"><path d="M7.5 17s6-5.2 6-9.7A6 6 0 0 0 1.5 7.3C1.5 11.8 7.5 17 7.5 17z"/><circle cx="7.5" cy="7.2" r="2.2"/></svg>';

  static const bell =
      '<svg width="18" height="19" viewBox="0 0 18 19" fill="none" stroke="#f5f0e8" stroke-width="1.7" stroke-linecap="round"><path d="M4 8a5 5 0 0 1 10 0c0 4 1.4 5.4 1.4 5.4H2.6S4 12 4 8z"/><path d="M7.2 16.4a2 2 0 0 0 3.6 0"/></svg>';

  static const search =
      '<svg width="17" height="17" viewBox="0 0 17 17" fill="none" stroke="#64748b" stroke-width="1.9" stroke-linecap="round"><circle cx="7.3" cy="7.3" r="5.6"/><path d="M11.4 11.4L15.5 15.5"/></svg>';

  static const filterSliders =
      '<svg width="19" height="19" viewBox="0 0 19 19" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round"><path d="M2 5.5h11M15.5 5.5h1.5M2 13.5h4M8.5 13.5h8.5"/><circle cx="14" cy="5.5" r="2.2"/><circle cx="7" cy="13.5" r="2.2"/></svg>';

  static const clock =
      '<svg width="21" height="21" viewBox="0 0 22 22" fill="none" stroke="#1a5c58" stroke-width="1.8"><circle cx="11" cy="11" r="8"/><path d="M11 6.5V11l3 1.8" stroke-linecap="round"/></svg>';

  static const star =
      '<svg width="11" height="11" viewBox="0 0 12 12" fill="#d4841a"><path d="M6 0l1.8 3.7 4.2.6-3 3 .7 4.1L6 9.4 2.3 11.4l.7-4.1-3-3 4.2-.6z"/></svg>';

  static const heartOutline =
      '<svg width="19" height="18" viewBox="0 0 20 18" fill="none" stroke="#d4841a" stroke-width="1.8" stroke-linejoin="round"><path d="M10 16.5S1.8 11.4 1.8 6.3A4.3 4.3 0 0 1 10 4.4a4.3 4.3 0 0 1 8.2 1.9c0 5.1-8.2 10.2-8.2 10.2z"/></svg>';

  static const heartFilled =
      '<svg width="19" height="18" viewBox="0 0 20 18" fill="#d4841a" stroke="#d4841a" stroke-width="1.8" stroke-linejoin="round"><path d="M10 16.5S1.8 11.4 1.8 6.3A4.3 4.3 0 0 1 10 4.4a4.3 4.3 0 0 1 8.2 1.9c0 5.1-8.2 10.2-8.2 10.2z"/></svg>';

  static const chatBubble =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#1a5c58" stroke-width="1.8" stroke-linejoin="round"><path d="M17.5 9.5a7 7 0 0 1-9.9 6.4L2.5 17.5l1.6-5.1A7 7 0 1 1 17.5 9.5z"/></svg>';

  static const phone =
      '<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="#f5f0e8" stroke-width="1.8" stroke-linejoin="round"><path d="M6.5 2.5l2.4 3.4-2 2a11 11 0 0 0 5.2 5.2l2-2 3.4 2.4-1.2 3.2c-5.2.7-11.8-5.9-11.1-11.1z"/></svg>';

  static const checkCircle =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1a5c58" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M7.5 12.5l3 3 6-6.5"/></svg>';

  static const send =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#f5f0e8" stroke-width="1.8" stroke-linejoin="round"><path d="M18 2L9 11M18 2l-5.8 16-3-7.2L2 7.8 18 2z"/></svg>';

  // Service grid (Home)
  static const serviceWashFold =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7"><rect x="4" y="2.5" width="18" height="21" rx="4"/><circle cx="13" cy="15" r="5.2"/><circle cx="13" cy="15" r="2"/><path d="M8 6.5h3" stroke-linecap="round"/></svg>';

  static const serviceIroning =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M3 18.5h13a6.5 6.5 0 0 0-6.5-6.5H6.5z"/><path d="M9.5 12V9.5A2.5 2.5 0 0 1 12 7h7.5" stroke-linecap="round"/><path d="M3 21.5h13" stroke-linecap="round"/></svg>';

  static const serviceDryClean =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M9.5 3L4 6v5h3v11h12V11h3V6l-5.5-3z"/><path d="M9.5 3a3.5 3.5 0 0 0 7 0"/></svg>';

  static const serviceCarpets =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><rect x="3.5" y="5" width="19" height="13" rx="2"/><path d="M3.5 18l-1.5 3M22.5 18l1.5 3M8 5v13M13 5v13M18 5v13"/></svg>';

  static const serviceShoeCare =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M3 18c0-3 2-5 5-6.5L14 8c2-1 4-1.5 6-1v6.5c2 .5 3.5 2 3.5 4V18a1.5 1.5 0 0 1-1.5 1.5H4.5A1.5 1.5 0 0 1 3 18z"/><path d="M9 11.5V17" stroke-linecap="round"/></svg>';

  static const serviceCurtains =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M3 5h20" stroke-linecap="round"/><path d="M6 5c0 6-2 9-2 15h6c-1-5 1-10 1-15"/><path d="M20 5c0 6 2 9 2 15h-6c1-5-1-10-1-15"/></svg>';

  static const serviceLeather =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M9 3L4 6.5V11h3v11h12V11h3V6.5L17 3c0 1.7-1.8 3-4 3s-4-1.3-4-3z"/><path d="M13 6v16" stroke-linecap="round"/></svg>';

  static const serviceBedding =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><rect x="3" y="9" width="20" height="12" rx="3"/><path d="M3 14h20"/><path d="M7 9V6a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v3"/></svg>';

  static const serviceDelicates =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><circle cx="13" cy="13" r="2.6"/><circle cx="13" cy="6.3" r="2.6"/><circle cx="13" cy="19.7" r="2.6"/><circle cx="6.3" cy="13" r="2.6"/><circle cx="19.7" cy="13" r="2.6"/></svg>';

  static const serviceSuits =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M13 3.5a2 2 0 1 0-2-2" stroke-linecap="round"/><path d="M13 5.5L4 10l2 3 4-2.3V21h6V10.7l4 2.3 2-3z"/></svg>';

  static const serviceStainRemoval =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><circle cx="10.5" cy="10.5" r="7"/><path d="M10.5 7v7M7 10.5h7" stroke-linecap="round"/><path d="M15.5 15.5L21.5 21.5" stroke-linecap="round"/></svg>';

  static const servicePillows =
      '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="#1a5c58" stroke-width="1.7" stroke-linejoin="round"><path d="M4 8a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M9 9c1.5 1.5 1.5 3.5 0 5M17 9c-1.5 1.5-1.5 3.5 0 5" stroke-linecap="round"/></svg>';

  // Bottom tab bar (source ICONS map — uses currentColor, ported with a
  // neutral default so callers recolor via AppIcon(color: ...))
  static const tabHome =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><path d="M2.5 8.4L10 2.5l7.5 5.9V17a1 1 0 0 1-1 1h-4v-5.5h-5V18h-4a1 1 0 0 1-1-1z"/></svg>';

  static const tabSearch =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round"><circle cx="8.6" cy="8.6" r="6.1"/><path d="M13 13l4.5 4.5"/></svg>';

  static const tabOrders =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><path d="M3.5 6.5l6.5-4 6.5 4v7l-6.5 4-6.5-4z"/><path d="M3.5 6.5l6.5 4 6.5-4M10 10.5v7"/></svg>';

  static const tabChat =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><path d="M17.5 9.5a7 7 0 0 1-9.9 6.4L2.5 17.5l1.6-5.1A7 7 0 1 1 17.5 9.5z"/></svg>';

  static const tabProfile =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><circle cx="10" cy="7" r="3.4"/><path d="M3.6 17.5a6.4 6.4 0 0 1 12.8 0"/></svg>';

  // Vendor/Admin tab bars (source ICONS map, same currentColor->#000
  // neutral-placeholder convention as the tab* icons above)
  static const tabDash =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><rect x="2.5" y="2.5" width="6.5" height="8" rx="1.6"/><rect x="11" y="2.5" width="6.5" height="5" rx="1.6"/><rect x="2.5" y="12.5" width="6.5" height="5" rx="1.6"/><rect x="11" y="9.5" width="6.5" height="8" rx="1.6"/></svg>';

  static const tabCatalog =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><path d="M2.5 2.5h7l8 8-7 7-8-8z"/><circle cx="6.3" cy="6.3" r="1.4"/></svg>';

  static const tabLogistics =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linejoin="round"><path d="M1.8 4.5h9.4v9H1.8zM11.2 7.5h3.4l3 3v3h-6.4z"/><circle cx="5.4" cy="15.5" r="1.8"/><circle cx="14.4" cy="15.5" r="1.8"/></svg>';

  static const tabSettings =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round"><path d="M3 6h9M15.5 6h1.5M3 14h1.5M8 14h9"/><circle cx="14" cy="6" r="2.2"/><circle cx="6.2" cy="14" r="2.2"/></svg>';

  static const tabReports =
      '<svg width="19" height="19" viewBox="0 0 20 20" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round"><path d="M2.5 17.5h15"/><path d="M5.5 14V9M10 14V4M14.5 14v-6"/></svg>';

  // Driver module
  static const foldedMap =
      '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="#1a5c58" stroke-width="1.9" stroke-linejoin="round"><path d="M2 6l5-3 4 3 5-3v12l-5 3-4-3-5 3z"/></svg>';
}
