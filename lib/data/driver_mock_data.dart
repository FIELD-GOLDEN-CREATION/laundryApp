import '../models/driver_job.dart';
import '../models/shift_row.dart';
import '../models/trip_ledger_row.dart';
import '../theme/colors.dart';

/// Static seed data for the Driver module — same 1:1 port-of-the-JS-mock
/// approach as data/vendor_mock_data.dart.

const kDriverPickupJobs = [
  DriverJob(
    id: '#LD-2492',
    whoLabel: 'Client pickup',
    who: 'Nina Alvarez',
    dist: '0.8 km',
    pay: 'TZS 18,720',
    addr: 'Apt 4B, 88 Toure Drive, Oyster Bay → Marina Fresh Laundry',
    note: 'Fragile lace dress — keep flat in the top crate. Ring the bell twice.',
  ),
  DriverJob(
    id: '#LD-2494',
    whoLabel: 'Client pickup',
    who: 'Owen Park',
    dist: '1.4 km',
    pay: 'TZS 21,060',
    addr: '12 Chole Road, Masaki, Apt 9 → Bright & Fold',
    note: 'Leave at gate if no answer. Two bags, one marked ironing only.',
  ),
  DriverJob(
    id: '#LD-2495',
    whoLabel: 'Client pickup',
    who: 'Grace Bello',
    dist: '2.6 km',
    pay: 'TZS 27,040',
    addr: '7 Kariakoo Street → Crisp Corner',
    note: 'Bulky duvet set, use the rear rack.',
  ),
];

const kDriverDeliveryJobs = [
  DriverJob(
    id: '#LD-2478',
    whoLabel: 'Vendor delivery',
    who: 'Marina Fresh → Grace Bello',
    dist: '1.9 km',
    pay: 'TZS 22,880',
    addr: 'Marina Fresh Laundry → 7 Kariakoo Street',
    note: 'Client requests contactless drop-off, photo on delivery.',
  ),
  DriverJob(
    id: '#LD-2475',
    whoLabel: 'Vendor delivery',
    who: 'Bright & Fold → Ivan Petrov',
    dist: '3.0 km',
    pay: 'TZS 30,160',
    addr: 'Bright & Fold → 41 Samora Avenue, Office 3',
    note: 'Reception closes at 5 PM — deliver before then.',
  ),
];

const kDriverShiftRows = [
  ShiftRow(id: '#LD-2488', who: 'Owen Park', meta: 'Delivered 12:52 PM · 2.4 km', amount: '+TZS 21,840', dot: AppColors.success),
  ShiftRow(id: '#LD-2486', who: 'Marina Fresh', meta: 'Picked up 11:30 AM · 1.1 km', amount: '+TZS 16,120', dot: AppColors.success),
  ShiftRow(id: '#LD-2483', who: 'Hana Sato', meta: 'Cancelled by client 10:14 AM', amount: '+TZS 3,900', dot: AppColors.rust),
];

/// (label, done fraction, cancelled fraction) per weekday for the Wallet
/// "This week" chart — ported from the source's `dWeek` (its `c||3` JS
/// falsy-zero quirk baked in as final percentages here).
const kDriverWeek = [
  ('Mon', .62, .03),
  ('Tue', .78, .12),
  ('Wed', .54, .03),
  ('Thu', .88, .10),
  ('Fri', .96, .03),
  ('Sat', .70, .18),
  ('Sun', .40, .03),
];

const kDriverLedger = [
  TripLedgerRow(id: '#LD-2488', date: '12 Aug', km: '2.4 km', base: 'TZS 16,640', tip: 'TZS 5,200', total: 'TZS 21,840'),
  TripLedgerRow(id: '#LD-2486', date: '12 Aug', km: '1.1 km', base: 'TZS 13,520', tip: 'TZS 2,600', total: 'TZS 16,120'),
  TripLedgerRow(id: '#LD-2479', date: '11 Aug', km: '4.8 km', base: 'TZS 25,480', tip: 'TZS 9,100', total: 'TZS 34,580'),
  TripLedgerRow(id: '#LD-2471', date: '11 Aug', km: '0.9 km', base: 'TZS 12,740', tip: 'TZS 0', total: 'TZS 12,740'),
  TripLedgerRow(id: '#LD-2465', date: '10 Aug', km: '3.2 km', base: 'TZS 19,760', tip: 'TZS 6,500', total: 'TZS 26,260'),
];

const kDriverScanItems = ['2 silk blouses', '1 lace evening dress', '1 wool coat', '2 cotton shirts', '1 linen scarf'];

const kDriverAppControls = [
  ('Mute in-app sound alerts', 'Job offers arrive silently'),
  ('Dark mode for night driving', 'Dims the app after sunset'),
];
