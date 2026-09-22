import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_sms_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Dashboard card: plan SMS left, extra SMS left, request-more action.
class SmsBalanceCard extends ConsumerStatefulWidget {
  const SmsBalanceCard({super.key});

  @override
  ConsumerState<SmsBalanceCard> createState() => _SmsBalanceCardState();
}

class _SmsBalanceCardState extends ConsumerState<SmsBalanceCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vendorSmsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final sms = ref.watch(vendorSmsProvider);
    final notifier = ref.read(vendorSmsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.sms_outlined, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS balance', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(
                      sms.loaded
                          ? (sms.allowed ? 'Plan SMS ${sms.remainingPlan} · Extra ${sms.remainingExtra}' : sms.reason.isEmpty ? 'SMS disabled' : sms.reason)
                          : 'Loading…',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: sms.isLoading ? null : () => _showRequestDialog(context, notifier),
                child: Text('Request', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sms.planQuota > 0 ? (sms.remainingPlan / sms.planQuota).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: AppColors.cream,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1 SMS per completed order · package & promo broadcasts share the same balance',
            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestDialog(BuildContext context, VendorSmsNotifier notifier) async {
    final ctrl = TextEditingController(text: '50');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Request more SMS', style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many extra messages do you need?', style: AppText.sans(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 50',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final count = int.tryParse(ctrl.text.trim()) ?? 0;
      if (count < 1) return;
      final sent = await notifier.requestMore(count);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent ? 'Request sent to admin.' : 'Could not send request (maybe one is pending).'),
          backgroundColor: sent ? AppColors.teal : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
