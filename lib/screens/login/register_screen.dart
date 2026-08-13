import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _register() {
    final error = ref.read(authProvider.notifier).registerClient(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          children: [
            Row(children: [IconButton(onPressed: () => context.pop(), icon: const AppIcon(AppIcons.backChevron, size: 9)), const SizedBox(width: 6), Text('Create account', style: AppText.serif(fontSize: 25))]),
            const SizedBox(height: 8),
            Text('Join Laundry and make pickup day easier.', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 24),
            _Field(label: 'FULL NAME', hint: 'e.g. Amara Reed', controller: _name),
            const SizedBox(height: 14),
            _Field(label: 'EMAIL', hint: 'name@mail.com', controller: _email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _Field(label: 'PHONE', hint: '+255 754 111 222', controller: _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _Field(label: 'PASSWORD', hint: 'At least 6 characters', controller: _password, obscure: true),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_error, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
            ],
            const SizedBox(height: 22),
            Material(color: AppColors.teal, borderRadius: BorderRadius.circular(18), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _register, child: Container(height: 54, alignment: Alignment.center, child: Text('Create client account', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream))))),
            const SizedBox(height: 14),
            Center(child: Text('Client accounts only · Vendors and staff are invited by admin', textAlign: TextAlign.center, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted))),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, required this.controller, this.obscure = false, this.keyboardType});
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppText.eyebrow()),
    const SizedBox(height: 7),
    Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(16)), child: TextField(controller: controller, obscureText: obscure, keyboardType: keyboardType, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700), decoration: InputDecoration.collapsed(hintText: hint, hintStyle: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)))),
  ]);
}
