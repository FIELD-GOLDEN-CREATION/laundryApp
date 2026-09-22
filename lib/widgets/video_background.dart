import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../theme/colors.dart';

/// Ambient background video for customer pages (dark mode only).
const kClientBackgroundVideoUrl =
    'https://res.cloudinary.com/diunukxtt/video/upload/v1790077839/14677931_1080_1920_30fps.mp4';

/// Single shared controller: initialized once, looped + muted + autoplaying,
/// reused by every customer page so the video never reloads on navigation.
final _backgroundVideoProvider = FutureProvider<VideoPlayerController?>((
  ref,
) async {
  try {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(kClientBackgroundVideoUrl),
    );
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    await controller.play();
    ref.onDispose(controller.dispose);
    return controller;
  } catch (_) {
    // Offline or codec failure — pages fall back to the solid dark color.
    return null;
  }
});

/// Full-bleed looping video with a dark readability overlay.
/// In light mode (or when the video can't load) it renders just [child].
class VideoBackground extends ConsumerStatefulWidget {
  const VideoBackground({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends ConsumerState<VideoBackground>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(_backgroundVideoProvider).valueOrNull;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      controller.play();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(_backgroundVideoProvider);
    final controller = video.valueOrNull;
    final ready = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF080D12)),
        if (ready)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        // Dark gradient overlay so text and cards stay readable over motion.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3080D12), Color(0x99080D12), Color(0xCC080D12)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Wraps a customer page body: video background in dark mode, plain passthrough otherwise.
class ClientBackground extends StatelessWidget {
  const ClientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppColors.isClientDark(context)) return child;
    return VideoBackground(child: child);
  }
}
