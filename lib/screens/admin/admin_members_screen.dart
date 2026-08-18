import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_mock_data.dart';
import '../../models/member_row.dart';
import '../../models/modal_copy.dart';
import '../../state/admin_members_state.dart';
import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/crud_form_modal.dart';

const _kMemberTabLabels = ['Clients', 'Vendors', 'Staff'];
const _kDetailRoutes = ['/admin/client', '/admin/vendor', '/admin/staff'];

class AdminMembersScreen extends ConsumerWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(adminMembersProvider);
    final notifier = ref.read(adminMembersProvider.notifier);
    final members = switch (tab) {
      0 => kClientMembers,
      1 => kVendorMembers,
      _ => kStaffMembers,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Members', style: AppText.serif(fontSize: 27)),
                        const SizedBox(height: 6),
                        Text(
                          '$kMemberCount accounts on the platform',
                          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                       onTap: () => showCrudFormModal(
                         context,
                         ModalKind.add,
                         onClientCreated: (name, email, phone, password) {
                           final error = ref.read(authProvider.notifier).registerClient(name: name, email: email, phone: phone, password: password);
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Client account created.')));
                         },
                       ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+', style: AppText.sans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.cream, height: 1)),
                            const SizedBox(width: 6),
                            Text('Add', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    for (var i = 0; i < _kMemberTabLabels.length; i++)
                      Expanded(
                        child: Material(
                          color: tab == i ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => notifier.pickTab(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  _kMemberTabLabels[i],
                                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: tab == i ? AppColors.teal : AppColors.muted),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    _MemberCard(member: members[i], onOpen: () => context.push(_kDetailRoutes[tab])),
                    if (i != members.length - 1) const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onOpen});
  final MemberRow member;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final (stateFg, stateBg) = switch (member.state) {
      'Suspended' => (AppColors.amber, AppColors.amberLight),
      'Pending' => (AppColors.muted, AppColors.creamDark),
      _ => (AppColors.teal, AppColors.tealMuted),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Row(
              children: [
                const SizedBox(width: 44, height: 44, child: PlaceholderImage(label: 'Avatar', borderRadius: 15)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        member.contact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: stateBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(member.state, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: stateFg)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ControlButton(label: 'Edit', color: AppColors.slate, onTap: () => showCrudFormModal(context, ModalKind.edit))),
              const SizedBox(width: 6),
              Expanded(child: _ControlButton(label: 'Reset pw', color: AppColors.teal, onTap: () => showCrudFormModal(context, ModalKind.reset))),
              const SizedBox(width: 6),
              Expanded(child: _ControlButton(label: 'Suspend', color: AppColors.amber, onTap: () => showCrudFormModal(context, ModalKind.suspend))),
              const SizedBox(width: 6),
              Expanded(child: _ControlButton(label: 'Delete', color: AppColors.danger, onTap: () => showCrudFormModal(context, ModalKind.delete))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: const BorderSide(color: AppColors.creamDark)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
        ),
      ),
    );
  }
}
