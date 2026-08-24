import 'package:flutter/widgets.dart';

import '../theme/colors.dart';
import 'order_line.dart';

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
    this.lines = const [],
    this.fulfillment = 'delivery',
    this.driver = '',
    this.deliveryFeeTzs = 0,
    this.customerName = '',
    this.customerPhone = '',
  });

  final String shop;
  final String id;
  final String items;
  final String status;
  final Color statusFg;
  final Color statusBg;
  final String date;
  final String total;
  final String paymentMethod;
  final String pickup;
  final String address;
  final int trackStep;
  final List<OrderLine> lines;
  final String fulfillment;
  final String driver;
  final int deliveryFeeTzs;
  final String customerName;
  final String customerPhone;

  Order copyWith({String? status, Color? statusFg, Color? statusBg, int? trackStep, int? deliveryFeeTzs}) => Order(
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
    lines: lines,
    fulfillment: fulfillment,
    driver: driver,
    deliveryFeeTzs: deliveryFeeTzs ?? this.deliveryFeeTzs,
    customerName: customerName,
    customerPhone: customerPhone,
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

OrderStatus selfOrderStatusForStep(int step) {
  switch (step) {
    case 0:
      return const OrderStatus('At shop', AppColors.teal, AppColors.tealMuted);
    case 1:
      return const OrderStatus('Sorted', AppColors.teal, AppColors.tealMuted);
    case 2:
      return const OrderStatus('Washing', AppColors.teal, AppColors.tealMuted);
    case 3:
      return const OrderStatus('Ready for collection', AppColors.teal, AppColors.tealMuted);
    default:
      return const OrderStatus('Promise booked', AppColors.amber, AppColors.amberLight);
  }
}
