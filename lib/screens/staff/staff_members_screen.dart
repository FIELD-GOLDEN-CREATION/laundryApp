import 'package:flutter/material.dart';

import '../../data/admin_mock_data.dart';
import '../../models/member_row.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StaffMembersScreen extends StatefulWidget {
  const StaffMembersScreen({super.key});

  @override
  State<StaffMembersScreen> createState() => _StaffMembersScreenState();
}

class _StaffMembersScreenState extends State<StaffMembersScreen> {
  int _selectedTab = 0;
  static const _tabLabels = ['Clients', 'Vendors'];

  @override
  Widget build(BuildContext context) {
    final members = _selectedTab == 0 ? kClientMembers : kVendorMembers;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Members', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 8),
            Text(
              '$kMemberCount accounts on the platform',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: List.generate(_tabLabels.length, (i) {
                  final selected = _selectedTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _tabLabels[i],
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.teal : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            for (final member in members) ...[
              _MemberCard(member: member),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final MemberRow member;

  @override
  Widget build(BuildContext context) {
    final stateColor = switch (member.state) {
      'Suspended' => AppColors.amber,
      'Pending' => AppColors.muted,
      _ => AppColors.teal,
    };
    final stateBg = switch (member.state) {
      'Suspended' => AppColors.amberLight,
      'Pending' => AppColors.creamDark,
      _ => AppColors.tealMuted,
    };

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
              color: stateColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              member.name.substring(0, 2).toUpperCase(),
              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: stateColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                Text(member.contact, style: AppText.sans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: stateBg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              member.state,
              style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: stateColor),
            ),
          ),
        ],
      ),
    );
  }
}
