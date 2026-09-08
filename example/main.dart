import 'package:agent_client_sdk/agent_client_sdk.dart';

Future<void> main() async {
  final client = AgentClient(baseUrl: 'https://agent.example.com', token: 'devtoken');
  final ssh = await client.health();
  print('health: ok=${ssh.ok}');
}
