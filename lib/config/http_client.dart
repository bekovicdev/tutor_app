import 'dart:io';

/// Single [HttpClient] instance shared and reused by every API service in
/// the app (auth, students, groups, lessons, payments, billing).
///
/// Previously each service created a brand new [HttpClient] for every
/// single request and force-closed it immediately afterwards
/// (`client.close(force: true)`). That throws away the underlying TCP/TLS
/// connection every time, forcing a full connection handshake on every API
/// call — a major, systemic source of latency/sluggishness, especially on
/// slower networks or when several requests fire close together (e.g.
/// switching tabs). Reusing one client lets Dart's [HttpClient] keep
/// connections alive and pool/reuse them across requests, which noticeably
/// speeds up the whole app without changing any request/response logic.
final HttpClient sharedApiHttpClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..idleTimeout = const Duration(seconds: 30)
  ..autoUncompress = true;
