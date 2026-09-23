import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../theme/colors.dart';

/// Ambient background video for customer pages (dark mode).
const kClientBackgroundVideoUrl =
    'https://res.cloudinary.com/diunukxtt/video/upload/v1790077839/14677931_1080_1920_30fps.mp4';

/// Cloud video for the sky blue-white theme.
const kSkyBackgroundVideoUrl =
    'https://res.cloudinary.com/diunukxtt/video/upload/v1790081871/2644023-uhd_3840_2024_25fps.mp4';

enum ClientBgVariant { dark, sky }

String _urlFor(ClientBgVariant variant) => variant == ClientBgVariant.sky
    ? kSkyBackgroundVideoUrl
    : kClientBackgroundVideoUrl;

/// One shared controller per variant: initialized once, looped + muted +
/// autoplaying. Auto-disposed when no page uses it, so the idle variant
/// never sits in memory.
final _backgroundVideoProvider = FutureProvider.autoDispose
    .family<VideoPlayerController?, ClientBgVariant>((ref, variant) async {
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(_urlFor(variant)),
        );
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
        ref.onDispose(controller.dispose);
        return controller;
      } catch (_) {
        // Offline or codec failure — pages fall back to the solid theme color.
        return null;
      }
    });

/// Full-bleed looping video with a readability overlay.
/// Falls back to the solid theme color when the video can't load.
class VideoBackground extends ConsumerStatefulWidget {
  const VideoBackground({
    super.key,
    required this.child,
    this.variant = ClientBgVariant.dark,
  });

  final Widget child;
  final ClientBgVariant variant;

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
    final controller = ref
        .read(_backgroundVideoProvider(widget.variant))
        .valueOrNull;
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
    final video = ref.watch(_backgroundVideoProvider(widget.variant));
    final controller = video.valueOrNull;
    final ready = controller != null && controller.value.isInitialized;
    final sky = widget.variant == ClientBgVariant.sky;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: sky ? AppColors.skyBg : const Color(0xFF080D12)),
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
        // Readability overlay: light black for dark mode, opacified cloud
        // blue for the sky theme.
        sky
            ? const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x8C2E7CC2),
                      Color(0x662E7CC2),
                      Color(0xB80C3E6E),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              )
            : const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x59080D12),
                      Color(0x33080D12),
                      Color(0x66080D12),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
        widget.child,
      ],
    );
  }
}

/// Wraps a customer page body: themed video background for dark/sky modes,
/// plain passthrough in light mode.
///
/// NOTE: the video itself lives once at the customer tab shell
/// ([app_router.dart]) — one shared player for all pages. Screen-level
/// uses of this widget are intentionally passthroughs (kept so call sites
/// don't need to change); do not add another VideoBackground per screen.
class ClientBackground extends ConsumerWidget {
  const ClientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}
