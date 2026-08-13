/// A row in the Admin Members list (Clients/Vendors/Drivers all share this
/// shape). [state] is one of 'Active' | 'Pending' | 'Suspended' — the
/// screen derives the pill colors from it, same as the source's `map()`.
class MemberRow {
  const MemberRow({required this.name, required this.contact, required this.state});

  final String name;
  final String contact;
  final String state;
}
