import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readyOrders = kActiveOrders.where((o) => o.status == 'Washing' || o.status == 'Sorted').toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Staff Portal', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 8),
            Text(
              'Mama Ngina Street, 2nd Floor',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shift Active', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        const SizedBox(height: 2),
                        Text(
                          'Checking in customers · ${kActiveOrders.length} orders today',
                          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _ActionCard(icon: Icons.qr_code_scanner, label: 'Scan\nOrder', color: AppColors.teal),
                const SizedBox(width: 12),
                _ActionCard(icon: Icons.person_add_outlined, label: 'Check In\nCustomer', color: AppColors.mint),
                const SizedBox(width: 12),
                _ActionCard(icon: Icons.check_circle_outline, label: 'Mark\nCollected', color: AppColors.rust),
              ],
            ),
            const SizedBox(height: 24),

            Text('PENDING COLLECTION', style: AppText.eyebrow()),
            const SizedBox(height: 12),
            for (final order in readyOrders.take(3)) ...[
              _PendingCard(order: order),
              const SizedBox(height: 10),
            ],
            if (readyOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No pending orders', style: AppText.sans(fontSize: 13, color: AppColors.muted)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: order.statusBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              order.shop.substring(0, 2).toUpperCase(),
              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: order.statusFg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shop, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                Text('${order.id} · ${order.items}', style: AppText.sans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: order.statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  order.status.toUpperCase(),
                  style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: order.statusFg),
                ),
              ),
              const SizedBox(height: 4),
              Text(order.date, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
