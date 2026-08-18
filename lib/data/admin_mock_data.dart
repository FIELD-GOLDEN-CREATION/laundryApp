import 'package:flutter/widgets.dart';

import '../models/admin_order_row.dart';
import '../models/alert_item.dart';
import '../models/key_value_field.dart';
import '../models/map_pin.dart';
import '../models/member_row.dart';
import '../models/report_metric.dart';
import '../models/sys_stat_card.dart';
import '../models/vendor_load_card.dart';
import '../theme/colors.dart';

/// Static seed data for the Admin module — see data/vendor_mock_data.dart
/// for why this is a separate file from the customer app's mock_data.dart.

const kSysCards = [
  SysStatCard(label: 'Active orders', value: '128', delta: '▲ 9%', deltaFg: AppColors.mint),
  SysStatCard(label: 'Drivers online', value: '19', delta: '3 idle', deltaFg: Color(0xB3F5F0E8)),
  SysStatCard(label: 'Vendors open', value: '42', delta: '2 offline', deltaFg: AppColors.amber),
  SysStatCard(label: 'Revenue today', value: 'TZS 24.4M', delta: '▲ 14%', deltaFg: AppColors.mint),
];

const kLiveDrivers = '19';

const kDriverMapPins = [
  MapPin(initial: 'D', label: 'Daniel · #2481', bg: AppColors.teal, left: 0.22, top: 0.28),
  MapPin(initial: 'K', label: 'Kofi · #2490', bg: AppColors.teal, left: 0.70, top: 0.22),
  MapPin(initial: 'I', label: 'Ivan · #2475', bg: AppColors.teal, left: 0.34, top: 0.70),
  MapPin(initial: 'N', label: 'Nadia · #2501', bg: AppColors.teal, left: 0.78, top: 0.66),
  MapPin(initial: 'G', label: 'Grace · #2467', bg: AppColors.teal, left: 0.52, top: 0.46),
];

const kAdminAlerts = [
  AlertItem(
    title: '#LD-2488 unassigned for 12 min',
    sub: 'No driver in Temeke · client waiting',
    tag: 'Unassigned',
    accentColor: AppColors.amber,
    tagBg: AppColors.amberLight,
  ),
  AlertItem(
    title: 'Pickup overdue · #LD-2479',
    sub: 'Driver Kofi is 40 min behind schedule',
    tag: 'Delayed',
    accentColor: AppColors.amber,
    tagBg: AppColors.amberLight,
  ),
  AlertItem(
    title: 'Crisp Corner cancelled 3 orders',
    sub: 'Machine breakdown reported 1 h ago',
    tag: 'Vendor',
    accentColor: AppColors.danger,
    tagBg: AppColors.dangerLight,
  ),
];

const kVelocityBarFractions = [.22, .44, .58, .48, .62, .86, 1.0, .64, .30];
const kVelocityBarLabels = ['7a', '9a', '11a', '1p', '3p', '5p', '7p', '9p', '11p'];

const kRangeChipLabels = ['Today', 'Last 7 days', 'This month', 'Custom'];
const kHourChipLabels = ['All hours', '6 – 10', '10 – 14', '14 – 18', '18 – 22'];

const kVendorLoads = [
  VendorLoadCard(name: 'Marina Fresh', volume: '34', queue: 'Queue of 7 · healthy', pct: 0.52, over: false),
  VendorLoadCard(name: 'Bright & Fold', volume: '28', queue: 'Queue of 14 · heavy', pct: 0.88, over: true),
  VendorLoadCard(name: 'Crisp Corner', volume: '11', queue: 'Queue of 2 · idle', pct: 0.18, over: false),
];

const kAdminOrders = [
  AdminOrderRow(
    id: '#LD-2492',
    status: 'In wash',
    statusFg: AppColors.teal,
    statusBg: AppColors.tealMuted,
    client: 'Nina Alvarez',
    vendor: 'Marina Fresh',
    driver: 'Daniel O.',
    time: 'Today 09:12',
  ),
  AdminOrderRow(
    id: '#LD-2488',
    status: 'Unassigned',
    statusFg: AppColors.amber,
    statusBg: AppColors.amberLight,
    client: 'Owen Park',
    vendor: 'Bright & Fold',
    driver: '— none —',
    time: 'Today 10:04',
  ),
  AdminOrderRow(
    id: '#LD-2481',
    status: 'Out for delivery',
    statusFg: AppColors.teal,
    statusBg: AppColors.tealMuted,
    client: 'Amara Reed',
    vendor: 'Marina Fresh',
    driver: 'Kofi A.',
    time: 'Today 06:40',
  ),
  AdminOrderRow(
    id: '#LD-2390',
    status: 'Refunded',
    statusFg: AppColors.muted,
    statusBg: AppColors.creamDark,
    client: 'Grace Bello',
    vendor: 'Crisp Corner',
    driver: 'Ivan P.',
    time: 'Jul 28 14:20',
  ),
];

const kMemberCount = '1,482';

const kClientMembers = [
  MemberRow(id: -1, name: 'Amara Reed', contact: 'amara.reed@gmail.com · 24 orders', state: 'Active', role: 'customer'),
  MemberRow(id: -2, name: 'Owen Park', contact: 'owen.park@gmail.com · 11 orders', state: 'Active', role: 'customer'),
  MemberRow(id: -3, name: 'Hana Sato', contact: 'hana.sato@gmail.com · 3 orders', state: 'Pending', role: 'customer'),
  MemberRow(id: -4, name: 'Luis Ferrer', contact: 'luis.f@gmail.com · 7 orders', state: 'Suspended', role: 'customer'),
];

const kVendorMembers = [
  MemberRow(id: -5, name: 'Marina Fresh Laundry', contact: 'Selma Duarte · 34 orders today', state: 'Active', role: 'vendor'),
  MemberRow(id: -6, name: 'Bright & Fold', contact: 'Tomas Lund · 28 orders today', state: 'Active', role: 'vendor'),
  MemberRow(id: -7, name: 'Crisp Corner', contact: 'Priya Nair · machine breakdown', state: 'Suspended', role: 'vendor'),
];

const kDriverMembers = [
  MemberRow(id: -8, name: 'Daniel Okafor', contact: 'Vehicle · T 342 KLM · on duty', state: 'Active', role: 'driver'),
  MemberRow(id: -9, name: 'Kofi Asante', contact: 'Motorcycle · MC 109 RTX · on duty', state: 'Active', role: 'driver'),
  MemberRow(id: -10, name: 'Ivan Petrov', contact: 'Bicycle · Ilala', state: 'Pending', role: 'driver'),
];

const kClientName = 'Amara Reed';
const kClientEmail = 'amara.reed@gmail.com · +255 754 220 441';
const kClientHistory = [
  KeyValueField('#LD-2481 · Marina Fresh', '12 Aug · 8 items · TZS 90,350'),
  KeyValueField('#LD-2390 · Crisp Corner', '28 Jul · 2 suits · TZS 49,400'),
  KeyValueField('#LD-2361 · Marina Fresh', '19 Jul · 11 items · TZS 107,120'),
  KeyValueField('#LD-2298 · Bright & Fold', '02 Jul · 5 items · TZS 43,940'),
];

const kVendorBiz = 'Marina Fresh Laundry';
const kVendorOwner = 'Selma Duarte';
const kVendorFields = [
  KeyValueField('Owner name', 'Selma Duarte'),
  KeyValueField('Business name', 'Marina Fresh Laundry Ltd'),
  KeyValueField('Contact', '+255 765 550 112'),
  KeyValueField('Operational status', 'Open · 07:00 – 21:00'),
  KeyValueField('Orders today', '34'),
];

const kDriverName = 'Daniel Okafor';
const kDriverFields = [
  KeyValueField('Full name', 'Daniel Okafor'),
  KeyValueField('NIDA number', '1998-0417-2288-31'),
  KeyValueField('Plate number', 'T · 342 KLM'),
  KeyValueField('Home location', '22 Ali Hassan Mwinyi Road, Kinondoni'),
  KeyValueField('Phone', '+255 744 418 820'),
];

const kTransportLabels = ['Vehicle', 'Motorcycle', 'Bicycle', 'Foot'];

const kAgentLabels = ['All agents', 'Selma D.', 'Kofi A.', 'Nadia B.'];
const kPeriodLabels = ['Today', 'Week', 'Month', 'Quarter'];
const kPeriodScopeLabels = ['Today', 'This week', 'This month', 'This quarter'];

const kReportMetrics = [
  ReportMetric(
    label: 'New clients',
    value: '214',
    pct: '+18%',
    pctFg: AppColors.teal,
    note: 'Onboarded this period',
    bar: 0.68,
  ),
  ReportMetric(
    label: 'Cancelled orders',
    value: '37',
    pct: '4.2%',
    pctFg: AppColors.amber,
    note: 'Of 882 placed orders',
    bar: 0.12,
  ),
  ReportMetric(
    label: 'Success rate',
    value: '94.6%',
    pct: '834 / 882',
    pctFg: AppColors.teal,
    note: 'Completed vs placed',
    bar: 0.94,
  ),
];

const kReportBarLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kReportBarFractions = [.62, .74, .88, .70, .96, 1.0, .54];

const kPermissionLabels = [
  ('Manage orders', 'Staff can reassign drivers and refund'),
  ('Manage members', 'Create, suspend and delete accounts'),
  ('Edit vendor pricing', 'Override catalog prices platform-wide'),
  ('View financial reports', 'Access earnings and payout data'),
];
const kDefaultPermissionsOn = [true, true, false, true];

const kNotificationToggleLabels = ['Mute system sounds', 'Desktop push alerts', 'Delayed pickup warnings'];
const kDefaultNotificationsOn = [false, true, true];
