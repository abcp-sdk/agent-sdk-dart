# Agent typed client SDK for Dart/Flutter

Connect client for `agent.v1.AgentService`, talking DIRECTLY to the abc agent
backend (no easylab gateway, no REST). Dart counterpart of
`abcp-sdk/agent-sdk-go` + `abcp-sdk/agent-sdk-typescript`.

**This package ships only the buf-generated code.** There is no hand-written
wrapper: the caller builds its own `connect.Transport` (HTTP client, codec,
interceptors) and hands it to the generated `AgentServiceClient`.

```dart
import 'package:agent_client_sdk/agent_client_sdk.dart';
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/protocol/connect.dart' as protocol;
import 'package:connectrpc/http2.dart';

final transport = protocol.Transport(
  baseUrl: 'https://agent.example.com',
  codec: const ProtoCodec(),
  httpClient: createHttpClient(transport: Http2ClientTransport()),
);
final agent = AgentServiceClient(transport);
final res = await agent.health(HealthRequest());
```

Consumed as a git dependency:

```yaml
dependencies:
  agent_client_sdk:
    git:
      url: https://github.com/abcp-sdk/agent-sdk-dart.git
      ref: v0.6.0
```
