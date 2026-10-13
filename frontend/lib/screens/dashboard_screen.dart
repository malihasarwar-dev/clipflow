import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../state/auth_state.dart';
import '../state/clip_controller.dart';
import '../widgets/ad_slot.dart';
import '../widgets/clip_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_stepper.dart';

/// Hero + URL input, live progress, results gallery and ad placements (sidebar + below results).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final _ytRe = RegExp(
      r'^https?://(www\.|m\.)?(youtube\.com/(watch\?v=|shorts/|live/)|youtu\.be/)[\w\-]{6,}',
      caseSensitive: false);

  final _url = TextEditingController();
  late final ClipController _clips;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _clips = ClipController(auth.api, onUnauthorized: auth.logout);
  }

  @override
  void dispose() {
    _clips.dispose();
    _url.dispose();
    super.dispose();
  }

  void _generate() {
    final value = _url.text.trim();
    if (!_ytRe.hasMatch(value)) {
      setState(() => _inputError = 'Paste a full YouTube video link (youtube.com/watch… or youtu.be/…).');
      return;
    }
    setState(() => _inputError = null);
    _clips.start(value);
  }

  // ---- sections -----------------------------------------------------------

  Widget _topBar(AuthState auth) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(gradient: CF.brandGradient, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.bolt_rounded, size: 22),
        ),
        const SizedBox(width: 10),
        const Text('ClipFlow',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const Spacer(),
        if (auth.user?['picture'] != null)
          CircleAvatar(radius: 15, backgroundImage: NetworkImage(auth.user!['picture'] as String))
        else
          const CircleAvatar(radius: 15, backgroundColor: CF.violet, child: Icon(Icons.person, size: 17)),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(auth.displayName,
              overflow: TextOverflow.ellipsis, style: const TextStyle(color: CF.textDim, fontSize: 13.5)),
        ),
        const SizedBox(width: 6),
        IconButton(tooltip: 'Log out', onPressed: auth.logout, icon: const Icon(Icons.logout_rounded, size: 20)),
      ]);

  Widget _hero(bool busy) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(
          shaderCallback: (r) => CF.brandGradient.createShader(r),
          child: const Text('Turn any YouTube video into viral Shorts',
              style: TextStyle(fontSize: 46, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
        ),
        const SizedBox(height: 14),
        const Text('Paste a link. We transcribe, pick the best 30–60 second hooks, crop to 9:16 and add captions.',
            style: TextStyle(fontSize: 16.5, color: CF.textDim, height: 1.5)),
        const SizedBox(height: 28),
        GlassCard(
          glow: CF.cyan,
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(builder: (context, c) {
            final stacked = c.maxWidth < 560;
            final field = TextField(
              controller: _url,
              enabled: !busy,
              onSubmitted: (_) => _generate(),
              decoration: const InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=…',
                prefixIcon: Icon(Icons.link_rounded, color: CF.textDim),
              ),
            );
            final button = GradientButton(
              label: 'Generate clips',
              icon: Icons.auto_awesome_rounded,
              
              loading: busy,
              expanded: stacked,
              onPressed: _generate,
            );
            return stacked
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [field, const SizedBox(height: 10), button])
                : Row(children: [Expanded(child: field), const SizedBox(width: 12), button]);
          }),
        ),
        if (_inputError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text(_inputError!, style: const TextStyle(color: CF.danger, fontSize: 13.5)),
          ),
      ]);

  Widget _status() => ListenableBuilder(
        listenable: _clips,
        builder: (context, _) {
          switch (_clips.phase) {
            case JobPhase.processing:
              return Padding(
                padding: const EdgeInsets.only(top: 28),
                child: ProgressStepper(
                    stageIndex: _clips.stageIndex,
                    progress: _clips.progress,
                    title: _clips.videoTitle),
              );
            case JobPhase.failed:
              return Padding(
                padding: const EdgeInsets.only(top: 28),
                child: GlassCard(
                  glow: CF.danger,
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: CF.danger),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_clips.error ?? 'Processing failed.')),
                  ]),
                ),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      );

  Widget _results() => ListenableBuilder(
        listenable: _clips,
        builder: (context, _) {
          if (_clips.clips.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_clips.phase == JobPhase.done ? 'Your Shorts are ready' : 'Shorts so far',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                const gap = 20.0;
                final cols = (c.maxWidth / 250).floor().clamp(1, 4);
                final w = ((c.maxWidth - gap * (cols - 1)) / cols).clamp(180.0, 340.0);
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  for (var i = 0; i < _clips.clips.length; i++)
                    SizedBox(width: w, child: ClipCard(clip: _clips.clips[i], index: i)),
                ]);
              }),
              const SizedBox(height: 32),
              // Ad placement: directly below the result players.
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 728;
                return Center(
                    child: AdSlot(
                        slotId: AppConfig.adSlotResults,
                        width: wide ? 728 : 320,
                        height: wide ? 90 : 100));
              }),
            ]),
          );
        },
      );

  Widget _sidebar() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ad placement: sidebar.
        const AdSlot(slotId: AppConfig.adSlotSidebar, width: 300, height: 250),
        const SizedBox(height: 24),
        const GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tips for better clips', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            SizedBox(height: 12),
            Text('• Talking-head videos, podcasts and tutorials work best.\n'
                '• Clear speech gives cleaner captions.\n'
                '• Videos up to 180 minutes are supported.\n'
                '• Only clip content you own or have permission to reuse.',
                style: TextStyle(color: CF.textDim, height: 1.65, fontSize: 13.5)),
          ]),
        ),
        const SizedBox(height: 16), // Thori si space
        // === Yeh raha Terms & Conditions ka button ===
        TextButton(
          onPressed: () {
            context.go('/terms'); // GoRouter ke zariye page kholne ka tareeqa
          },
          child: const Text(
            'Terms & Conditions',
            style: TextStyle(color: CF.textDim, fontSize: 13),
          ),
        ),
      
      ]);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 1040;
                final pad = c.maxWidth < 600 ? 16.0 : 32.0;
                final main = ListenableBuilder(
                  listenable: _clips,
                  builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _hero(_clips.phase == JobPhase.processing),
                    _status(),
                    _results(),
                  ]),
                );
                return Padding(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad, 56),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _topBar(auth),
                    SizedBox(height: wide ? 56 : 36),
                    if (wide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: main),
                        const SizedBox(width: 40),
                        SizedBox(width: 300, child: _sidebar()),
                      ])
                    else ...[
                      main,
                      const SizedBox(height: 40),
                      _sidebar(),
                    ],
                  ]),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
