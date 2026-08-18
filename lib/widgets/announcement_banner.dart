import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../state/profile_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'account_sheet.dart';
import 'remote_image.dart';

// Source references: the supplied woman and man Unsplash illustration pages.
// Those URLs are web pages, not image files, so direct Unsplash files keep the
// avatar visible at runtime.
const _kWomanAvatarImage = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=160&q=85';
const _kManAvatarImage = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=160&q=85';

class AnnouncementBanner extends ConsumerStatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  ConsumerState<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends ConsumerState<AnnouncementBanner> {
  static const _messages = ['OFFERS', 'DISCOUNT', 'FREE PICKUP', 'NEW THIS WEEK'];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openProfile(BuildContext context, UserRole role) {
    if (role == UserRole.customer) {
      context.go('/profile');
    } else {
      showAccountSheet(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final guest = auth.role == UserRole.guest;
    final profile = ref.watch(profileProvider);

    return Container(
      height: guest ? 58 : 62,
      padding: const EdgeInsets.fromLTRB(16, 7, 12, 7),
      decoration: const BoxDecoration(color: AppColors.slate),
      child: Row(
        children: [
          const Expanded(child: _FreshFoldLogo()),
          if (guest) ...[
            _HeaderAction(label: 'Log in', onTap: () => context.push('/login')),
            const SizedBox(width: 8),
            _HeaderAction(label: 'Register', filled: true, onTap: () => context.push('/register')),
          ] else ...[
            _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () => context.push('/notifs')),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _openProfile(context, auth.role),
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                  width: 36,
                  height: 36,
                child: RemoteImage(
                  url: auth.role == UserRole.customer ? _kWomanAvatarImage : _kManAvatarImage,
                  fallback: profile.photoLabel,
                  circle: true,
                  borderRadius: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FreshFoldLogo extends StatelessWidget {
  const _FreshFoldLogo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 34,
        height: 32,
        child: Stack(
          children: [
            Positioned(left: 1, top: 11, child: _Bubble(size: 14, color: AppColors.teal)),
            Positioned(left: 10, top: 2, child: _Bubble(size: 16, color: AppColors.cream)),
            Positioned(left: 21, top: 13, child: _Bubble(size: 12, color: AppColors.amber)),
            const Positioned(left: 11, top: 13, child: Icon(Icons.local_laundry_service_rounded, size: 12, color: AppColors.slate)),
          ],
        ),
      ),
      Text('FreshFold', style: AppText.serif(fontSize: 18, color: AppColors.cream)),
    ],
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color.withValues(alpha: 0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.28))));
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) => Material(
    color: filled ? AppColors.amber : Colors.transparent,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: filled ? null : Border.all(color: AppColors.cream.withValues(alpha: 0.35))),
        child: Text(label, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: filled ? AppColors.slate : AppColors.cream)),
      ),
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 18, color: AppColors.cream))),
  );
}
