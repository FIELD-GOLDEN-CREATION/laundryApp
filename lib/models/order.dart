import 'package:flutter/widgets.dart';

import '../theme/colors.dart';

/// trackStep value meaning the order has been submitted but not yet picked
/// up by a driver — earlier than index 0 of kTrackSteps.
const kOrderPlacedStep = -1;

class Order {
  const Order({
    required this.shop,
    required this.id,
    required this.items,
    required this.status,
    required this.statusFg,
    required this.statusBg,
    required this.date,
    required this.total,
    required this.trackStep,
    this.paymentMethod = '',
    this.pickup = '',
    this.address = '',
  });

  final String shop;
  final String id;
  final String items;
  final String status;
  final Color statusFg;
  final Color statusBg;
  final String date;
  final String total;

  /// How the order was paid, e.g. "Mobile money · M-Pesa" or "Card · Visa •••• 4412".
  final String paymentMethod;

  /// Pickup day/time summary, e.g. "Thu 13, 6 – 8 PM".
  final String pickup;

  /// Pickup address line.
  final String address;

  /// Index into kTrackSteps the order has reached, or kOrderPlacedStep if
  /// it's been submitted but not yet picked up.
  final int trackStep;

  Order copyWith({String? status, Color? statusFg, Color? statusBg, int? trackStep}) => Order(
    shop: shop,
    id: id,
    items: items,
    status: status ?? this.status,
    statusFg: statusFg ?? this.statusFg,
    statusBg: statusBg ?? this.statusBg,
    date: date,
    total: total,
    trackStep: trackStep ?? this.trackStep,
    paymentMethod: paymentMethod,
    pickup: pickup,
    address: address,
  );
}

class OrderStatus {
  const OrderStatus(this.label, this.fg, this.bg);

  final String label;
  final Color fg;
  final Color bg;
}

/// Status label + badge colors for a given track step — shared by the
/// Orders list badge and the Track screen heading so advancing a demo
/// order's step keeps both in sync.
OrderStatus orderStatusForStep(int step) {
  switch (step) {
    case 0:
      return const OrderStatus('Picked up', AppColors.teal, AppColors.tealMuted);
    case 1:
      return const OrderStatus('Sorted', AppColors.teal, AppColors.tealMuted);
    case 2:
      return const OrderStatus('Washing', AppColors.teal, AppColors.tealMuted);
    case 3:
      return const OrderStatus('Out for delivery', AppColors.teal, AppColors.tealMuted);
    default:
      return const OrderStatus('Order placed', AppColors.amber, AppColors.amberLight);
  }
}
