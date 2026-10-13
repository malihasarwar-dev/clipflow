// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../core/config.dart';

/// A Google AdSense display unit embedded in Flutter Web.
///
/// How it works: Flutter paints to a canvas, so a real DOM node is mounted through
/// [HtmlElementView]. The node contains the standard `<ins class="adsbygoogle">` tag plus
/// the `adsbygoogle.push({})` call. The loader script lives in web/index.html.
///
/// Until a real publisher ID + slot ID are configured it renders a tasteful placeholder.
class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.slotId,
    this.width = 300,
    this.height = 250,
  });

  final String slotId;
  final double width;
  final double height;

  static final Set<String> _registered = {};

  bool get _configured =>
      !AppConfig.adsenseClient.contains('XXXX') && !slotId.contains('XXXX');

  String get _viewType => 'adsense-$slotId-${width.toInt()}x${height.toInt()}';

  void _register() {
    if (!_registered.add(_viewType)) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final container = html.DivElement()
        ..style.width = '${width.toInt()}px'
        ..style.height = '${height.toInt()}px'
        ..style.overflow = 'hidden';
      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'inline-block'
        ..style.width = '${width.toInt()}px'
        ..style.height = '${height.toInt()}px'
        ..setAttribute('data-ad-client', AppConfig.adsenseClient)
        ..setAttribute('data-ad-slot', slotId);
      final push = html.ScriptElement()
        ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';
      container
        ..append(ins)
        ..append(push);
      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_configured) {
      _register();
      content = HtmlElementView(viewType: _viewType);
    } else {
      content = _Placeholder(width: width, height: height);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 2),
          child: Text('Advertisement',
              style: TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 0.4)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: width, height: height, child: content),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('Ad space ${width.toInt()}×${height.toInt()}',
          style: const TextStyle(color: Colors.white30, fontSize: 12)),
    );
  }
}
