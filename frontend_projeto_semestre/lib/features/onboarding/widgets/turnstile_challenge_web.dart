import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Iframe de mesma origem recebe Turnstile e comunica token sem dados de conta.
class TurnstileChallenge extends StatefulWidget {
  const TurnstileChallenge({
    super.key,
    required this.siteKey,
    required this.onToken,
  });
  final String siteKey;
  final ValueChanged<String?> onToken;

  @override
  State<TurnstileChallenge> createState() => _TurnstileChallengeState();
}

class _TurnstileChallengeState extends State<TurnstileChallenge> {
  static int _counter = 0;
  late final String _instance;
  late final JSFunction _handler;

  @override
  void initState() {
    super.initState();
    _instance = 'automatize_turnstile_' + (_counter++).toString();
    ui_web.platformViewRegistry.registerViewFactory(
      _instance,
      (int viewId) {
        final uri = Uri(
          path: '/turnstile-frame.html',
          queryParameters: {
            'sitekey': widget.siteKey,
            'instance': _instance,
          },
        );
        final element = web.HTMLIFrameElement()
          ..src = uri.toString()
          ..width = '100%'
          ..height = '90';
        element.style.border = '0';
        element.setAttribute('title', 'Verificação antirobô');
        return element;
      },
    );
    _handler = ((web.Event event) {
      final message = event as web.MessageEvent;
      if (message.origin != web.window.location.origin) return;
      final raw = message.data.dartify();
      if (raw is! String) return;
      Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return;
      }
      if (decoded is! Map || decoded['kind'] != 'automatize-turnstile' ||
          decoded['instance'] != _instance || !mounted) {
        return;
      }
      final token = decoded['token'];
      widget.onToken(token is String && token.isNotEmpty ? token : null);
    }).toJS;
    web.window.addEventListener('message', _handler);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90, width: double.infinity,
    child: HtmlElementView(viewType: _instance),
  );
}
