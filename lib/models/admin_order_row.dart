import 'package:flutter/widgets.dart';

import 'key_value_field.dart';

class AdminOrderRow {
  const AdminOrderRow({
    required this.id,
    required this.status,
    required this.statusFg,
    required this.statusBg,
    required this.client,
    required this.vendor,
    required this.driver,
    required this.time,
  });

  final String id;
  final String status;
  final Color statusFg;
  final Color statusBg;
  final String client;
  final String vendor;
  final String driver;
  final String time;

  List<KeyValueField> get fields => [
    KeyValueField('Client', client),
    KeyValueField('Vendor', vendor),
    KeyValueField('Driver', driver),
    KeyValueField('Placed', time),
  ];
}
