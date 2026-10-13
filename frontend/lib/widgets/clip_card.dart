import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../core/theme.dart';
import '../state/clip_controller.dart';
import 'glass_card.dart';

/// One generated Short: 9:16 player (lazy-loaded), virality score and download button.
class ClipCard extends StatefulWidget {
  const ClipCard({super.key, required this.clip, required this.index});
  final ClipResult clip;
  final int index;

  @override
  State<ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<ClipCard> {
  VideoPlayerController? _vc;
  bool _loading = false;

  Future<void> _toggle() async {
    if (_vc == null) {
      setState(() => _loading = true);
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.clip.url));
      await c.initialize();
      await c.setLooping(true);
      c.addListener(() => mounted ? setState(() {}) : null);
      _vc = c;
      _loading = false;
      await c.play();
      if (mounted) setState(() {});
      return;
    }
    _vc!.value.isPlaying ? await _vc!.pause() : await _vc!.play();
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final playing = _vc?.value.isPlaying ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(10),
      radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: GestureDetector(
              onTap: _toggle,
              child: Stack(fit: StackFit.expand, children: [
                if (_vc != null && _vc!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                        width: _vc!.value.size.width,
                        height: _vc!.value.size.height,
                        child: VideoPlayer(_vc!)),
                  )
                else
                  Image.network(clip.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: CF.surface)),
                if (!playing)
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                          border: Border.all(color: Colors.white24)),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded, size: 34),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(clip.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _chip(Icons.timer_outlined, '${clip.duration.toStringAsFixed(0)}s', CF.cyan),
              _chip(Icons.local_fire_department_rounded,
                  'Hook score ${clip.score.toStringAsFixed(1)}', CF.pink),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () =>
                    launchUrl(Uri.parse(clip.downloadUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download MP4', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
