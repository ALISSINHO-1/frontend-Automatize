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
    this.onError,
  });
  final String siteKey;
  final ValueChanged<String?> onToken;
  final ValueChanged<String>? onError;

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
          ..height = '145';
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
      final status = decoded['status'];
      final token = decoded['token'];
      widget.onToken(token is String && token.isNotEmpty ? token : null);
      if (status == 'error') {
        final code = decoded['errorCode'];
        widget.onError?.call(code is String && code.isNotEmpty
            ? 'Não foi possível carregar o CAPTCHA (código $code).'
            : 'Não foi possível carregar o CAPTCHA.');
      }

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
    height: 145, width: double.infinity,
    child: HtmlElementView(viewType: _instance),
  );
}
