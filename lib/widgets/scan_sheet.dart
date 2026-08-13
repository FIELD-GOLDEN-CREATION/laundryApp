import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/driver_mock_data.dart';
import '../state/driver_queue_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'barcode_strip.dart';

/// The "Verify & collect" scan sheet opened from the Driver queue when a job
/// steps past "Verify & collect" (ports the source's `dScan`/`dCheck`). The
/// checklist and tag id are shared across every job's scan, same quirk as
/// the source (never reset per-job). Reads [driverQueueProvider] via an
/// internal [Consumer] so checkbox taps rebuild live without needing a ref
/// from the caller.
void showScanSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Consumer(
        builder: (context, sheetRef, _) {
          final state = sheetRef.watch(driverQueueProvider);
          final notifier = sheetRef.read(driverQueueProvider.notifier);
          final count = state.checklist.where((c) => c).length;

          return Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Text('Verify & collect', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text(
                  'Scan the garment tag, then check every item off.',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.creamDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const BarcodeStrip(height: 56),
                      const SizedBox(height: 10),
                      Text(
                        'MF-2492-A',
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.creamDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < kDriverScanItems.length; i++)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => notifier.toggleCheck(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: i == kDriverScanItems.length - 1 ? Colors.transparent : AppColors.cream),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _ScanCheckbox(checked: state.checklist[i]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(kDriverScanItems[i], style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              notifier.closeScan();
                              Navigator.of(sheetContext).pop();
                            },
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 7,
                        child: Material(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              notifier.confirmScan();
                              Navigator.of(sheetContext).pop();
                            },
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Text(
                                'Collect $count items',
                                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ScanCheckbox extends StatelessWidget {
  const _ScanCheckbox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.success : Colors.white,
        border: Border.all(color: checked ? AppColors.success : const Color(0xFFD7D2C6), width: 1.8),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: checked ? const Text('✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)) : null,
    );
  }
}
