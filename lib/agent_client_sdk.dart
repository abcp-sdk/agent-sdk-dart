// Agent typed client SDK for Dart/Flutter.
//
// One entrypoint, one baseUrl: the abc agent backend (agent.v1.AgentService).
// Pure Connect client — no easylab gateway, no REST.
//
// The HTTP stack is selected per platform via conditional imports:
//   - web (browser)        -> `package:connectrpc/web.dart`   (fetch)
//   - all native platforms  -> `package:connectrpc/http2.dart` (HTTP/2 over TLS)
//
// This slim package ships ONLY the generated messages + the typed
// AgentServiceClient, plus a `createAgentClient` factory that wires up the
// transport (self-signed CA + bearer token). There are no convenience methods —
// call the generated RPCs directly (e.g. `agent.listSessions(ListSessionsRequest())`).
library;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/protocol/connect.dart' as protocol;

import 'src/gen/agent/v1/agent.connect.client.dart' as agent_client;
import 'src/transport/transport_stub.dart'
    if (dart.library.io) 'src/transport/transport_io.dart'
    if (dart.library.js_interop) 'src/transport/transport_web.dart';

/// Export the agent.v1 message + RPC surface.
export 'src/gen/agent/v1/agent.pb.dart';
export 'src/gen/agent/v1/agent.connect.client.dart';
export 'src/transport/transport_stub.dart'
    if (dart.library.io) 'src/transport/transport_io.dart'
    if (dart.library.js_interop) 'src/transport/transport_web.dart'
    show buildHttpClient;

typedef AgentServiceClient = agent_client.AgentServiceClient;

/// CA certificate (PEM) used on native HTTP/2-TLS. Ignored on web.
class AgentTls {
  const AgentTls({this.caPem});
  final String? caPem;
}

/// Bearer-auth interceptor: attaches `Authorization: Bearer <token>`.
connect.Interceptor _bearer(String token) {
  return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
    return (req) async {
      req.headers.set('authorization', ['Bearer $token']);
      return next(req);
    };
  };
}

/// Build a typed agent.v1 client over the given base.
///
/// Wires a Connect transport (HTTP/2-TLS on native, fetch on web) with the
/// bearer token and (optionally) a custom CA PEM for self-signed agents.
///
/// There are no convenience methods — call the generated
/// [agent_client.AgentServiceClient] methods directly, e.g.
///   `client.health(HealthRequest())`, `client.listSessions(ListSessionsRequest())`.
AgentServiceClient createAgentClient({
  required String baseUrl,
  required String token,
  AgentTls? tls,
}) {
  final trimmed =
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final transport = protocol.Transport(
    baseUrl: trimmed,
    codec: const ProtoCodec(),
    httpClient: buildHttpClient(caPem: tls?.caPem),
    interceptors: [
      if (token.isNotEmpty) _bearer(token),
    ],
  );
  return AgentServiceClient(transport);
}
