class MemberRow {
  const MemberRow({
    required this.id,
    required this.name,
    required this.contact,
    required this.state,
    required this.role,
  });

  final int id;
  final String name;
  final String contact;
  final String state;
  final String role;

  factory MemberRow.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'customer';
    final email = json['email'] as String? ?? '';
    final phone = json['phone'] as String?;
    final contactParts = <String>[email];
    if (phone != null && phone.isNotEmpty) contactParts.add(phone);

    return MemberRow(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      contact: contactParts.join(' · '),
      state: 'Active',
      role: role,
    );
  }
}
