// Agent typed client SDK for Dart/Flutter.
//
// This package ships the buf-generated `agent.v1.AgentService` message + RPC
// surface, and NOTHING hand-written. Per the connectrpc convention the caller
// owns the transport: build a `connect.Transport` (with whatever HTTP client,
// codec and interceptors it needs) and hand it to the generated
// `AgentServiceClient`.
//
//   final transport = protocol.Transport(
//     baseUrl: base,
//     codec: const ProtoCodec(),
//     httpClient: myHttpClient,
//     interceptors: [myAuthInterceptor],
//   );
//   final agent = AgentServiceClient(transport);
library;

export 'src/gen/agent/v1/agent.pb.dart';
export 'src/gen/agent/v1/agent.connect.client.dart';
