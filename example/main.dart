import 'package:agent_client_sdk/agent_client_sdk.dart';
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/protocol/connect.dart' as protocol;
import 'package:connectrpc/http2.dart';

Future<void> main() async {
  final transport = protocol.Transport(
    baseUrl: 'https://agent.example.com',
    codec: const ProtoCodec(),
    httpClient: createHttpClient(
      transport: Http2ClientTransport(),
    ),
  );
  final agent = AgentServiceClient(transport);
  final res = await agent.health(HealthRequest());
  print('health: ok=${res.ok}');
}
