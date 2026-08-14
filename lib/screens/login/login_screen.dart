import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../state/auth_state.dart';
import '../../state/login_form_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

const _kDefaultReason = 'Customers track orders. Vendors run the shop. Admins oversee the platform.';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = ref.read(loginFormProvider);
    final error = ref.read(authProvider.notifier).login(form.email, form.password);
    if (error != null) {
      ref.read(loginFormProvider.notifier).setError(error);
      return;
    }
    final role = ref.read(authProvider).role;
    final redirectPath = form.redirectPath;
    final redirectExtra = form.redirectExtra;
    ref.read(loginFormProvider.notifier).reset();
    context.go(roleHomePath(role));
    if (redirectPath != null) context.push(redirectPath, extra: redirectExtra);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginFormProvider, (prev, next) {
      if (_emailController.text != next.email) _emailController.text = next.email;
      if (_passwordController.text != next.password) _passwordController.text = next.password;
    });
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _AuthIntro(
                title: 'Hello!',
                subtitle: 'Clean clothes. Clear days.',
                onBack: () => context.go('/home'),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back!', style: AppText.serif(fontSize: 28, color: AppColors.cream)),
                    const SizedBox(height: 5),
                    Text(form.reason.isEmpty ? _kDefaultReason : form.reason, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.68))),
                    const SizedBox(height: 22),
                    _AuthLabel('EMAIL ADDRESS'),
                    const SizedBox(height: 7),
                    _LoginField(controller: _emailController, hint: 'Enter email address', onChanged: notifier.setEmail),
                    const SizedBox(height: 15),
                    _AuthLabel('PASSWORD'),
                    const SizedBox(height: 7),
                    _LoginField(controller: _passwordController, hint: 'Enter password', obscure: true, onChanged: notifier.setPassword, onSubmitted: _submit),
                    if (form.error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(form.error, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amberLight)),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _submit,
                          child: Center(child: Text('Login  →', style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.teal))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: Text('DEMO ACCESS', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.cream.withValues(alpha: 0.56)))),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: _DemoAccountButton(label: 'Customer', email: 'user@gmail.com', color: AppColors.teal, onTap: notifier.fillCustomer)), const SizedBox(width: 8), Expanded(child: _DemoAccountButton(label: 'Vendor', email: 'vendor@gmail.com', color: AppColors.amber, onTap: notifier.fillVendor))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: _DemoAccountButton(label: 'Admin', email: 'admin@gmail.com', color: AppColors.slate, onTap: notifier.fillAdmin)), const SizedBox(width: 8), Expanded(child: _DemoAccountButton(label: 'Driver', email: 'driver@gmail.com', color: AppColors.success, onTap: notifier.fillDriver))]),
                    const SizedBox(height: 18),
                    Center(child: TextButton(onPressed: () => context.push('/register'), child: Text('Don\'t have an account?  Register', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.cream)))),
                    Center(child: TextButton(onPressed: () => context.go('/home'), child: Text('Keep browsing as guest', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.62))))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  const _AuthIntro({required this.title, required this.subtitle, required this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconButton(onPressed: onBack, padding: EdgeInsets.zero, alignment: Alignment.centerLeft, icon: const AppIcon(AppIcons.backChevron, size: 9)),
      const SizedBox(height: 18),
      const Icon(Icons.local_laundry_service_rounded, size: 34, color: AppColors.teal),
      const SizedBox(height: 12),
      Text(title, style: AppText.serif(fontSize: 28, color: AppColors.teal)),
      const SizedBox(height: 5),
      Text(subtitle, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
    ]),
  );
}

class _AuthLabel extends StatelessWidget {
  const _AuthLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.cream.withValues(alpha: 0.72), letterSpacing: 0.5));
}

class _LoginField extends StatelessWidget {
  const _LoginField({required this.controller, required this.hint, required this.onChanged, this.obscure = false, this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), border: Border.all(color: Colors.white.withValues(alpha: 0.24)), borderRadius: BorderRadius.circular(14)),
    child: TextField(controller: controller, obscureText: obscure, onChanged: onChanged, onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(), style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.cream), decoration: InputDecoration.collapsed(hintText: hint, hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.45)))),
  );
}

class _DemoAccountButton extends StatelessWidget {
  const _DemoAccountButton({required this.label, required this.email, required this.color, required this.onTap});
  final String label;
  final String email;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: color == AppColors.amber ? AppColors.amber : AppColors.cream)),
              const SizedBox(height: 2),
              Text(email, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.58))),
            ],
          ),
        ),
      ),
    );
  }
}
