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
    // Land on the role's home first (so there's a normal shell + back
    // target), then push the screen the guest was actually headed to on
    // top of it — rather than `go`-ing straight there with nothing behind
    // it to pop back to.
    context.go(roleHomePath(role));
    if (redirectPath != null) {
      context.push(redirectPath, extra: redirectExtra);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The demo-account buttons fill the fields from outside (via the
    // provider), so the controllers need to be resynced whenever that
    // happens — but never while the user is mid-typing, hence the
    // text-differs guard rather than an unconditional overwrite.
    ref.listen(loginFormProvider, (prev, next) {
      if (_emailController.text != next.email) _emailController.text = next.email;
      if (_passwordController.text != next.password) _passwordController.text = next.password;
    });
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: Container(
                width: double.infinity,
                color: AppColors.teal,
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -60,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => context.go('/home'),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Center(child: AppIcon(AppIcons.backChevron, size: 9, color: AppColors.cream)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text('Welcome back', style: AppText.serif(fontSize: 30, color: AppColors.cream)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 250,
                              child: Text(
                                form.reason.isEmpty ? _kDefaultReason : form.reason,
                                style: AppText.sans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cream.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMAIL', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _LoginField(
                    controller: _emailController,
                    hint: 'you@mail.com',
                    onChanged: notifier.setEmail,
                  ),
                  const SizedBox(height: 18),
                  Text('PASSWORD', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _LoginField(
                    controller: _passwordController,
                    hint: '••••••••',
                    obscure: true,
                    onChanged: notifier.setPassword,
                    onSubmitted: _submit,
                  ),
                  if (form.error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        form.error,
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.amber),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _submit,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          'Log in',
                          style: AppText.sans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(height: 1, color: AppColors.creamDark)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'DEMO ACCOUNTS',
                            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.muted),
                          ),
                        ),
                        const Expanded(child: Divider(height: 1, color: AppColors.creamDark)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _DemoAccountButton(
                          label: 'Customer',
                          email: 'user@gmail.com',
                          color: AppColors.teal,
                          onTap: notifier.fillCustomer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DemoAccountButton(
                          label: 'Vendor',
                          email: 'vendor@gmail.com',
                          color: AppColors.amber,
                          onTap: notifier.fillVendor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DemoAccountButton(
                          label: 'Admin',
                          email: 'admin@gmail.com',
                          color: AppColors.slate,
                          onTap: notifier.fillAdmin,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DemoAccountButton(
                          label: 'Driver',
                          email: 'driver@gmail.com',
                          color: AppColors.success,
                          onTap: notifier.fillDriver,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/home'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: Text(
                          'Keep browsing as guest',
                          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({required this.controller, required this.hint, required this.onChanged, this.obscure = false, this.onSubmitted});

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
        style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
      ),
    );
  }
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.creamDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 3),
              Text(
                email,
                style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
