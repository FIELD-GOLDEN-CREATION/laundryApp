import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/vendor_earnings_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';

String _fileStamp() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}';
}

String _todayLabel() {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final n = DateTime.now();
  return '${n.day} ${months[n.month - 1]} ${n.year}';
}

/// Builds the shared PDF summary: breakdown, order-amount trend, every
/// order with its amount, and the full rating summary with comments.
Future<List<int>> buildEarningsPdf(
  VendorEarningsState state,
  TrendRange range,
) async {
  final doc = pw.Document();
  final orders = state.orderLines;
  final trend = state.trendFor(range);
  final trendTotal = trend.fold<double>(0, (s, p) => s + p.amountTzs);
  final counts = state.starCounts;
  const teal = PdfColor.fromInt(0xFF1A5C58);
  const muted = PdfColor.fromInt(0xFF64748B);
  const cream = PdfColor.fromInt(0xFFF5F0E8);

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: teal)),
      );

  pw.Widget moneyRow(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 11, color: muted)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: bold ? 13 : 11,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Earnings summary',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: teal)),
          pw.SizedBox(height: 2),
          pw.Text('Generated ${_todayLabel()} · Trend: ${range.label}',
              style: const pw.TextStyle(fontSize: 10, color: muted)),
          pw.Divider(color: cream),
        ],
      ),
      build: (_) => [
        sectionTitle('Earnings breakdown'),
        moneyRow('Gross revenue', formatTzs(state.totalRevenue)),
        moneyRow('Paid out', formatTzs(state.totalPayouts)),
        moneyRow('Net balance', formatTzs(state.balance), bold: true),
        sectionTitle('Order-amount trend (${range.label})'),
        moneyRow('Period total', formatTzs(trendTotal), bold: true),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Period', 'Amount (TZS)'],
          data: [for (final p in trend) [p.label, p.amountTzs.round().toString()]],
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: teal),
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        sectionTitle('Orders (${orders.length})'),
        if (orders.isEmpty)
          pw.Text('No completed orders yet.',
              style: const pw.TextStyle(fontSize: 11))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Order', 'Details', 'Amount (TZS)'],
            data: [
              for (final l in orders) [l.label, l.sub, l.amountTzs.round().toString()],
            ],
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: teal),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        sectionTitle('Reviews & ratings'),
        pw.Text(
          state.reviews.isEmpty
              ? 'No reviews yet.'
              : '${state.avgRating.toStringAsFixed(1)} average from ${state.reviews.length} review${state.reviews.length == 1 ? '' : 's'}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        for (var s = 5; s >= 1; s--)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text('$s star — ${counts[s] ?? 0} order${(counts[s] ?? 0) == 1 ? '' : 's'}',
                style: const pw.TextStyle(fontSize: 10, color: muted)),
          ),
        pw.SizedBox(height: 8),
        for (final r in state.reviews) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${r.name} · ${r.stars.length.clamp(1, 5)} stars',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(r.text, style: const pw.TextStyle(fontSize: 10, color: muted)),
              ],
            ),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}

/// Shares the PDF summary via the platform share sheet.
Future<void> shareEarningsPdf(
  VendorEarningsState state,
  TrendRange range,
) async {
  final bytes = await buildEarningsPdf(state, range);
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: 'earnings-summary-${_fileStamp()}.pdf',
  );
}

/// Offscreen summary card rendered to a PNG (fixed width, no scrolling so
/// it captures fully) and shared as an image.
class PngSummaryCard extends StatelessWidget {
  const PngSummaryCard({super.key, required this.state, required this.range});

  final VendorEarningsState state;
  final TrendRange range;

  @override
  Widget build(BuildContext context) {
    final orders = state.orderLines;
    final trend = state.trendFor(range);
    final trendTotal = trend.fold<double>(0, (s, p) => s + p.amountTzs);
    final counts = state.starCounts;
    final shown = orders.take(6).toList();

    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppText.sans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted)),
              Text(value,
                  style: AppText.sans(
                      fontSize: bold ? 15 : 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate)),
            ],
          ),
        );

    return Container(
      width: 420,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earnings summary',
                    style: AppText.serif(fontSize: 22, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${_todayLabel()} · Trend: ${range.label}',
                    style: AppText.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          row('Gross revenue', formatTzs(state.totalRevenue)),
          row('Paid out', formatTzs(state.totalPayouts)),
          row('Net balance', formatTzs(state.balance), bold: true),
          const Divider(height: 20),
          row('${range.label} order total', formatTzs(trendTotal), bold: true),
          const SizedBox(height: 6),
          Text('ORDERS (${orders.length})', style: AppText.eyebrow()),
          const SizedBox(height: 6),
          for (final l in shown) row(l.label, formatTzs(l.amountTzs)),
          if (orders.length > shown.length)
            Text('…and ${orders.length - shown.length} more',
                style: AppText.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted)),
          const Divider(height: 20),
          Text(
            state.reviews.isEmpty
                ? 'No reviews yet'
                : '${state.avgRating.toStringAsFixed(1)} average · ${state.reviews.length} reviews',
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (var s = 5; s >= 1; s--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '$s star — ${counts[s] ?? 0} order${(counts[s] ?? 0) == 1 ? '' : 's'}',
                style: AppText.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Captures the summary card offscreen and shares it as a PNG image.
Future<void> shareEarningsImage(
  VendorEarningsState state,
  TrendRange range,
) async {
  final controller = ScreenshotController();
  final bytes = await controller.captureFromWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          child: PngSummaryCard(state: state, range: range),
        ),
      ),
    ),
    pixelRatio: 2.5,
    delay: const Duration(milliseconds: 150),
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: 'earnings-summary-${_fileStamp()}.png',
          mimeType: 'image/png',
        ),
      ],
      text: 'Earnings summary · ${_todayLabel()}',
    ),
  );
}
