# Agent typed client SDK for Dart/Flutter (agent.v1.AgentService over
# Connect / HTTP2-TLS).
#
# This is the Dart counterpart of abcp-sdk/agent-sdk-go + agent-sdk-typescript.
# It talks DIRECTLY to the abc agent backend; it does NOT go through the
# easylab gateway and exposes only the agent.v1 surface (no lab/ops/registry).

```dart
final client = AgentClient(baseUrl: 'https://agent.example.com', token: 'devtoken');
final sessions = await client.listSessions();
```

Consumed as a git dependency:

```yaml
dependencies:
  agent_client_sdk:
    git:
      url: https://github.com/abcp-sdk/agent-sdk-dart.git
      ref: v0.1.0
```
