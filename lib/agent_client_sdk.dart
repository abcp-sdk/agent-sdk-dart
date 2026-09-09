// Agent typed client SDK for Dart/Flutter.
//
// One entrypoint, one baseUrl: the abc agent backend (agent.v1.AgentService).
// Pure Connect client — no easylab gateway, no REST.
//
// This package ships ONLY the generated messages + the typed AgentServiceClient,
// and the platform transport primitive `buildHttpClient` (HTTP/2-TLS on native
// via a self-signed CA, fetch on web). Per the connectrpc convention the caller
// builds its own `connect.Transport` and hands it to the generated client:
//
//   final transport = protocol.Transport(
//     baseUrl: base,
//     codec: const ProtoCodec(),
//     httpClient: buildHttpClient(caPem: ca),
//     interceptors: [bearerInterceptor(token)],
//   );
//   final agent = AgentServiceClient(transport);
library;

import 'package:connectrpc/connect.dart' as connect;

import 'src/gen/agent/v1/agent.connect.client.dart' as agent_client;

/// Export the agent.v1 message + RPC surface, and the transport primitive.
export 'src/gen/agent/v1/agent.pb.dart';
export 'src/gen/agent/v1/agent.connect.client.dart';
export 'src/transport/transport_stub.dart'
    if (dart.library.io) 'src/transport/transport_io.dart'
    if (dart.library.js_interop) 'src/transport/transport_web.dart'
    show buildHttpClient;

/// The generated Connect client for agent.v1.AgentService.
typedef AgentServiceClient = agent_client.AgentServiceClient;

/// Build a Connect bearer-auth interceptor: attaches
/// `Authorization: Bearer <token>` to every request.
connect.Interceptor bearerInterceptor(String token) {
  return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
    return (req) async {
      req.headers.set('authorization', ['Bearer $token']);
      return next(req);
    };
  };
}
