import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Аккаунттың ашық WebSocket байланыстары (`/v1/live`).
///
/// Сервердегі деректер өзгергенде аккаунттың басқа құрылғыларына
/// `{"type":"changed"}` жібереді — олар бірден жаңа суретті сұрайды.
/// Өзгеріс болмаса (снимок бұрынғыдай), хабарлама жіберілмейді: әйтпесе
/// екі құрылғы бір-біріне шексіз «changed» жіберер еді.
class LiveHub {
  final _clients = <int, Set<LiveClient>>{};
  final _fingerprints = <int, String>{};

  int connections(int account) => _clients[account]?.length ?? 0;

  void add(LiveClient client) => (_clients[client.account] ??= {}).add(client);

  void remove(LiveClient client) {
    final set = _clients[client.account];
    set?.remove(client);
    if (set != null && set.isEmpty) _clients.remove(client.account);
  }

  /// Снимоктың «саусақ ізі»: server_time-сыз, тұрақты ретпен.
  static String fingerprint(Map<String, Object?> snapshot) {
    final copy = Map.of(snapshot)..remove('server_time');
    return sha256.convert(utf8.encode(jsonEncode(copy))).toString();
  }

  /// Деректер өзгерген болса — [except] құрылғысынан басқаларына хабарлау.
  /// Қайтарады: хабарланған байланыс саны.
  int publish(int account, String fingerprint, {String? except}) {
    if (_fingerprints[account] == fingerprint) return 0;
    _fingerprints[account] = fingerprint;
    var sent = 0;
    for (final c in [...?_clients[account]]) {
      if (except != null && c.device == except) continue;
      c.send({'type': 'changed'});
      sent++;
    }
    if (sent > 0) stdout.writeln('live: account $account → changed ×$sent');
    return sent;
  }

  /// Токен қайтарылғанда не аккаунт жойылғанда байланыстарды жабу.
  /// [unauthorizedCode] — клиент қайта қосылмайды; басқа код (мысалы,
  /// [restartCode]) — клиент кідіріспен қайта қосылады.
  void closeWhere(
    bool Function(LiveClient c) test, {
    int code = unauthorizedCode,
    String reason = 'unauthorized',
  }) {
    for (final set in [..._clients.values]) {
      for (final c in [...set]) {
        if (test(c)) c.close(code, reason);
      }
    }
  }

  static const unauthorizedCode = 4401;
  static const restartCode = 4503;

  void forget(int account) => _fingerprints.remove(account);
}

/// Бір құрылғының байланысы.
class LiveClient {
  LiveClient({
    required this.account,
    required this.device,
    required this.tokenHash,
    required this.channel,
  });

  final int account;
  final String? device;
  final String tokenHash;
  final WebSocketChannel channel;

  void send(Map<String, Object?> message) =>
      channel.sink.add(jsonEncode(message));

  void close(int code, String reason) => channel.sink.close(code, reason);
}
