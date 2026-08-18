import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  int _selectedFilter = 0;
  static const _filters = ['All', 'Active', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final allOrders = [...kActiveOrders, ...kCompletedOrders];
    final filteredOrders = switch (_selectedFilter) {
      1 => kActiveOrders,
      2 => kCompletedOrders,
      _ => allOrders,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                children: [
                  Text('Orders', style: AppText.serif(fontSize: 27)),
                  const SizedBox(height: 8),
                  Text(
                    '${filteredOrders.length} orders match the current filter',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  Row(
                    children: List.generate(_filters.length, (i) {
                      final selected = _selectedFilter == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.teal : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.teal : AppColors.creamDark),
                            ),
                            child: Text(
                              _filters[i],
                              style: AppText.sans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Orders
                  for (final order in filteredOrders) ...[
                    _OrderCard(order: order),
                    const SizedBox(height: 10),
                  ],
                  if (filteredOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No orders', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.id, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: order.statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  order.status,
                  style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: order.statusFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoTile(label: 'Shop', value: order.shop),
              const SizedBox(width: 12),
              _InfoTile(label: 'Items', value: order.items),
              const SizedBox(width: 12),
              _InfoTile(label: 'Placed', value: order.date),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.total, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate)),
              if (order.driver.isNotEmpty)
                Text(
                  'Driver: ${order.driver}',
                  style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.tabInactive)),
          const SizedBox(height: 2),
          Text(value, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
