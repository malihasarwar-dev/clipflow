import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'glass_card.dart';

/// Download -> Transcribe -> Hook extraction -> Render, with live progress.
class ProgressStepper extends StatelessWidget {
  const ProgressStepper({
    super.key,
    required this.stageIndex,
    required this.progress,
    this.title,
  });

  final int stageIndex; // 0..3
  final double progress; // 0..100
  final String? title;

  static const _steps = [
    (Icons.cloud_download_rounded, 'Downloading'),
    (Icons.graphic_eq_rounded, 'Transcribing'),
    (Icons.auto_awesome_rounded, 'Finding hooks'),
    (Icons.movie_creation_rounded, 'Rendering Shorts'),
  ];

  Widget _node(int i) {
    final done = i < stageIndex;
    final active = i == stageIndex;
    final color = done || active ? CF.cyan : Colors.white24;
    return SizedBox(
      width: 92,
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? CF.cyan.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: color, width: active ? 2 : 1.2),
            boxShadow: active
                ? [BoxShadow(color: CF.cyan.withValues(alpha: 0.55), blurRadius: 22)]
                : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            if (active)
              const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(strokeWidth: 2, color: CF.cyan)),
            Icon(done ? Icons.check_rounded : _steps[i].$1, size: 21, color: color),
          ]),
        ),
        const SizedBox(height: 10),
        Text(_steps[i].$2,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active || done ? Colors.white : CF.textDim)),
      ]),
    );
  }

  Widget _line(int i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            color: i < stageIndex ? CF.cyan : Colors.white12,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pct = progress.clamp(0, 100).toDouble();
    return GlassCard(
      glow: CF.violet,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(title ?? 'Working on your video…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(color: CF.cyan, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 22),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 520),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _node(i),
                if (i < _steps.length - 1) _line(i),
              ]
            ]),
          ),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(CF.violet),
          ),
        ),
      ]),
    );
  }
}
