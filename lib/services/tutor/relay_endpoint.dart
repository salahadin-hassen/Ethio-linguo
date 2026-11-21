import 'package:flutter/foundation.dart';

/// Where the tutor relay lives. Defaults to the build-time address
/// (`--dart-define=TUTOR_BASE_URL=...`) and can be changed on the device
/// (Speak > "The Professor is offline" > Tutor server), so a demo laptop
/// whose Wi-Fi address changed does not need a new build.
class RelayEndpoint extends ChangeNotifier {
  RelayEndpoint(this._url, {this.onSave});

  Uri? _url;
  final Future<void> Function(Uri? url)? onSave;

  Uri? get url => _url;

  static const defaultPort = 8787;

  /// Lenient parsing for typing on a phone: "192.168.1.20" becomes that
  /// host on plain HTTP, port 8787. Returns null for empty/invalid input.
  static Uri? parse(String? text) {
    final t = (text ?? '').trim();
    if (t.isEmpty) return null;
    final hasScheme = t.contains('://');
    final u = Uri.tryParse(hasScheme ? t : '//$t');
    if (u == null || u.host.isEmpty) return null;
    final scheme = hasScheme ? u.scheme : 'http';
    if (scheme != 'http' && scheme != 'https') return null;
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : (scheme == 'http' ? defaultPort : null),
    );
  }

  /// Saves [text]; returns false (and changes nothing) if it isn't a URL.
  Future<bool> set(String text) async {
    final u = parse(text);
    if (u == null) return false;
    _url = u;
    notifyListeners();
    await onSave?.call(u);
    return true;
  }
}
