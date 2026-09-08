// Native (io) transport: HTTP/2 over TLS (ALPN `h2`) via `package:connectrpc/http2.dart`.
// Used on all native platforms (Android/iOS/macOS/Linux/Windows).
import 'dart:convert';
import 'dart:io' as io;

import 'package:connectrpc/connect.dart' show HttpClient;
import 'package:connectrpc/http2.dart';

HttpClient buildHttpClient({String? caPem}) {
  final context = io.SecurityContext(withTrustedRoots: true);
  if (caPem != null && caPem.isNotEmpty) {
    context.setTrustedCertificatesBytes(utf8.encode(caPem));
  }
  return createHttpClient(
    transport: Http2ClientTransport(context: context),
  );
}
