import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

const _kRegisterWash = Color(0xFFEAF2FA);

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
      backgroundColor: _kRegisterWash,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 12, 24, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconButton(onPressed: () => context.pop(), padding: EdgeInsets.zero, alignment: Alignment.centerLeft, icon: const AppIcon(AppIcons.backChevron, size: 9)), const SizedBox(height: 16), const Icon(Icons.local_laundry_service_rounded, size: 34, color: AppColors.teal), const SizedBox(height: 12), Text('Create your account', style: AppText.serif(fontSize: 28, color: AppColors.teal)), const SizedBox(height: 5), Text('Sign up to continue your laundry journey.', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted))])),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: const BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create your client account', style: AppText.serif(fontSize: 25, color: AppColors.cream)),
                  const SizedBox(height: 5),
                  Text('A few details and you are ready to book.', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.68))),
                  const SizedBox(height: 20),
                  _Field(label: 'FULL NAME', hint: 'e.g. Amara Reed', controller: _name, lightLabel: true),
                  const SizedBox(height: 13),
                  _Field(label: 'EMAIL ADDRESS', hint: 'name@mail.com', controller: _email, keyboardType: TextInputType.emailAddress, lightLabel: true),
                  const SizedBox(height: 13),
                  _Field(label: 'MOBILE NUMBER', hint: '+255 754 111 222', controller: _phone, keyboardType: TextInputType.phone, lightLabel: true),
                  const SizedBox(height: 13),
                  _Field(label: 'PASSWORD', hint: 'At least 6 characters', controller: _password, obscure: true, lightLabel: true),
                  if (_error.isNotEmpty) ...[const SizedBox(height: 12), Text(_error, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amberLight))],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _register, child: Center(child: Text('Sign up  →', style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.teal))),),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(child: Text('Client accounts only · Staff are invited by admin', textAlign: TextAlign.center, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.62)))),
                  Center(child: TextButton(onPressed: () => context.pop(), child: Text('Already have an account?  Sign in', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.cream)))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, required this.controller, this.obscure = false, this.keyboardType, this.lightLabel = false});
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool lightLabel;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: lightLabel ? AppColors.cream.withValues(alpha: 0.72) : AppColors.muted, letterSpacing: 0.5)),
    const SizedBox(height: 7),
    Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), border: Border.all(color: Colors.white.withValues(alpha: 0.24)), borderRadius: BorderRadius.circular(14)), child: TextField(controller: controller, obscureText: obscure, keyboardType: keyboardType, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: lightLabel ? AppColors.cream : AppColors.slate), decoration: InputDecoration.collapsed(hintText: hint, hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: lightLabel ? AppColors.cream.withValues(alpha: 0.45) : AppColors.muted)))),
  ]);
}
