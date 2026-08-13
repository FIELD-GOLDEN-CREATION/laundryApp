/// One pickup (from a client) or delivery (from a vendor) task in the
/// driver's queue. `whoLabel` distinguishes the two ('Client pickup' vs
/// 'Vendor delivery'); step-derived display fields (tag/dots/step button)
/// are computed in the screen, same split as [VendorOrder].
class DriverJob {
  const DriverJob({
    required this.id,
    required this.whoLabel,
    required this.who,
    required this.dist,
    required this.pay,
    required this.addr,
    required this.note,
  });

  final String id;
  final String whoLabel;
  final String who;
  final String dist;
  final String pay;
  final String addr;
  final String note;
}
