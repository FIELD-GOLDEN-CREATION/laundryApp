import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/member_row.dart';
import '../../models/modal_copy.dart';
import '../../state/admin_members_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';

const _kMemberTabLabels = ['Clients', 'Vendors', 'Drivers'];
const _kDetailRoutes = ['/admin/client', '/admin/vendor', '/admin/driver'];
const _kTabRoles = ['customer', 'vendor', 'driver'];

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminMembersProvider.notifier).fetchMembers());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminMembersProvider);
    final notifier = ref.read(adminMembersProvider.notifier);
    final members = state.currentMembers;

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
                          '${state.clients.length + state.vendors.length + state.drivers.length} accounts on the platform',
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
                      onTap: () => _showAddMemberSheet(context, notifier),
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
                          color: state.tab == i ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => notifier.pickTab(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  _kMemberTabLabels[i],
                                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: state.tab == i ? AppColors.teal : AppColors.muted),
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
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 40, 22, 0),
                child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
              )
            else if (state.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 0),
                child: Center(
                  child: Column(
                    children: [
                      Text(state.error, style: AppText.sans(fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => notifier.fetchMembers(),
                        child: Text('Retry', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      ),
                    ],
                  ),
                ),
              )
            else if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 0),
                child: Center(
                  child: Text('No ${_kMemberTabLabels[state.tab].toLowerCase()} yet.', style: AppText.sans(fontSize: 13, color: AppColors.muted)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Column(
                  children: [
                    for (var i = 0; i < members.length; i++) ...[
                      _MemberCard(
                        member: members[i],
                        onOpen: () => context.push(_kDetailRoutes[state.tab]),
                        onDelete: () async {
                          final error = await notifier.deleteMember(members[i].id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? 'Member deleted.')),
                            );
                          }
                        },
                      ),
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

  void _showAddMemberSheet(BuildContext context, AdminMembersNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        var addRole = 0;
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final phoneController = TextEditingController();
        final passwordController = TextEditingController();

        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    Text('Add Member', style: AppText.serif(fontSize: 22)),
                    const SizedBox(height: 3),
                    Text('Create a new account on the platform.', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < _kMemberTabLabels.length; i++) ...[
                          if (i != 0) const SizedBox(width: 7),
                          Expanded(
                            child: Material(
                              color: addRole == i ? AppColors.teal : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: addRole == i ? AppColors.teal : AppColors.creamDark),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(() => addRole = i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Center(
                                    child: Text(
                                      _kMemberTabLabels[i].substring(0, _kMemberTabLabels[i].length - 1),
                                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: addRole == i ? AppColors.cream : AppColors.muted),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ModalField(label: 'FULL NAME', hint: 'e.g. Amara Reed', controller: nameController),
                    const SizedBox(height: 12),
                    _ModalField(label: 'EMAIL ADDRESS', hint: 'name@mail.com', controller: emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _ModalField(label: 'PHONE NUMBER', hint: '+255 754 111 222', controller: phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _ModalField(label: 'PASSWORD', hint: 'At least 6 characters', controller: passwordController, obscure: true),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 7,
                          child: Material(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                final error = await notifier.addMember(
                                  name: nameController.text,
                                  email: emailController.text,
                                  phone: phoneController.text,
                                  password: passwordController.text,
                                  role: _kTabRoles[addRole],
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error ?? 'Member created successfully.')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: Text(
                                  'Create Account',
                                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {});
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onOpen, required this.onDelete});
  final MemberRow member;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

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
              Expanded(child: _ControlButton(label: 'Edit', color: AppColors.slate, onTap: () {})),
              const SizedBox(width: 6),
              Expanded(child: _ControlButton(label: 'Reset pw', color: AppColors.teal, onTap: () {})),
              const SizedBox(width: 6),
              Expanded(child: _ControlButton(label: 'Suspend', color: AppColors.amber, onTap: () {})),
              const SizedBox(width: 6),
              Expanded(
                child: _ControlButton(
                  label: 'Delete',
                  color: AppColors.danger,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete ${member.name}?'),
                        content: Text('This will remove ${member.name} from the platform.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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

class _ModalField extends StatelessWidget {
  const _ModalField({required this.label, required this.hint, required this.controller, this.obscure = false, this.keyboardType});
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.creamDark),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}
