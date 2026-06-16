import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Cliente STOMP para eventos de trámites en tiempo real.
class TramiteSocketService {
  StompClient? _client;
  final _portafoliosController = StreamController<Map<String, dynamic>>.broadcast();
  final _portafolioDetailControllers = <String, StreamController<Map<String, dynamic>>>{};

  Stream<Map<String, dynamic>> get portafoliosStream => _portafoliosController.stream;

  Stream<Map<String, dynamic>> portafolioStream(String portafolioId) {
    _portafolioDetailControllers.putIfAbsent(
      portafolioId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return _portafolioDetailControllers[portafolioId]!.stream;
  }

  void connect() {
    if (_client?.connected == true) return;

    _client = StompClient(
      config: StompConfig(
        url: _resolveWsUrl(),
        onConnect: _onConnect,
        onWebSocketError: (_) {},
        onStompError: (_) {},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void _onConnect(StompFrame frame) {
    final client = _client;
    if (client == null) return;
    client.subscribe(
      destination: '/topic/portafolios',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _portafoliosController.add(data);
        } catch (_) {}
      },
    );
  }

  void subscribePortafolio(String portafolioId) {
    connect();
    final client = _client;
    if (client == null || client.connected != true) {
      Future.delayed(const Duration(milliseconds: 500), () => subscribePortafolio(portafolioId));
      return;
    }

    client.subscribe(
      destination: '/topic/portafolio/$portafolioId',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _portafolioDetailControllers[portafolioId]?.add(data);
        } catch (_) {}
      },
    );
  }

  void dispose() {
    disconnect();
    _portafoliosController.close();
    for (final c in _portafolioDetailControllers.values) {
      c.close();
    }
    _portafolioDetailControllers.clear();
  }
}

String _resolveWsUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  final envUrl = fromEnv.trim();
  String httpBase;
  if (envUrl.isNotEmpty) {
    httpBase = envUrl.endsWith('/api') ? envUrl.substring(0, envUrl.length - 4) : envUrl;
  } else {
    httpBase = 'https://npwch9fd-8081.brs.devtunnels.ms';
  }

  final uri = Uri.parse(httpBase);
  final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$wsScheme://${uri.host}$port/ws-native';
}
