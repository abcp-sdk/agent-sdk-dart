// Agent typed client SDK for Dart/Flutter.
//
// One entrypoint, one baseUrl: the abc agent backend (agent.v1.AgentService).
// This is a pure Connect client — no easylab gateway, no REST. It speaks
// HTTP/2 only (over TLS via ALPN `h2`; the connectrpc `createHttpClient()`
// refuses h2c unless you construct a cleartext transport yourself). The
// client is generated from agent/v1/agent.proto by buf.
//
// Usage:
//   final client = AgentClient(baseUrl: 'https://agent.example.com', token: '');
//   final sessions = await client.listSessions();
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/http2.dart';
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/protocol/connect.dart' as protocol;

import 'src/gen/agent/v1/agent.connect.client.dart' as agent_client;
import 'src/gen/agent/v1/agent.pb.dart' as agent_pb;

/// Export the agent.v1 message + RPC surface.
export 'src/gen/agent/v1/agent.pb.dart';
export 'src/gen/agent/v1/agent.connect.client.dart';

/// HTTPS-over-HTTP/2 certificate setup: a [SecurityContext] that the client
/// uses when negotiating ALPN `h2`. When [caPem] is provided the CA is added
/// to the trusted roots; otherwise the platform default trust store is used
/// (which works for public TLS certs).
class AgentTls {
  const AgentTls({this.caPem});
  final String? caPem;

  io.SecurityContext build({bool withTrustedRoots = true}) {
    final ctx = io.SecurityContext(withTrustedRoots: withTrustedRoots);
    final pem = caPem;
    if (pem != null && pem.isNotEmpty) {
      ctx.setTrustedCertificatesBytes(utf8.encode(pem));
    }
    return ctx;
  }
}

/// Throws when a call was rejected (non-OK Connect code).
class AgentException implements Exception {
  AgentException(this.code, this.message);
  final String code;
  final String? message;
  @override
  String toString() => 'AgentException($code): $message';
}

/// The typed agent client over agent.v1.AgentService.
///
/// [baseUrl] is protocol+host, no trailing slash required (e.g.
/// `https://agent.example.com`). It must be `https` for TLS; the default
/// transport only performs HTTP/2-over-TLS (ALPN `h2`).
class AgentClient {
  /// Base URL the transport points at (used to rebuild transports on CA
  /// change).
  final String baseUrl;

  /// Bearer token, attached to every request when non-empty.
  final String token;

  final connect.Transport _transport;

  /// Build a client. Provide [tls] to trust a custom CA (self-signed agent).
  AgentClient({required this.baseUrl, required this.token, AgentTls? tls})
      : _transport = _build(baseUrl, token, tls);

  static connect.Transport _build(
    String baseUrl,
    String token,
    AgentTls? tls,
  ) {
    final trimmed = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final context = tls?.build() ?? io.SecurityContext(withTrustedRoots: true);
    return protocol.Transport(
      baseUrl: trimmed,
      codec: const ProtoCodec(),
      httpClient: createHttpClient(
        transport: Http2ClientTransport(context: context),
      ),
      interceptors: [
        if (token.isNotEmpty) _bearer(token),
      ],
    );
  }

  static connect.Interceptor _bearer(String token) {
    return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
      return (req) async {
        req.headers.set('authorization', ['Bearer $token']);
        return next(req);
      };
    };
  }

  /// Agent surface (sessions/messages/prompt/watch/...).
  agent_client.AgentServiceClient get agent =>
      agent_client.AgentServiceClient(_transport);

  // ---- typed convenience helpers ----

  /// List sessions.
  Future<List<agent_pb.Session>> listSessions() async {
    final r = await agent.listSessions(agent_pb.ListSessionsRequest());
    return r.sessions;
  }

  /// Create a session.
  Future<agent_pb.Session> createSession({
    String? name,
    String? model,
    String? preset,
    String? org,
    String? repo,
    String? branch,
  }) async {
    final r = await agent.createSession(agent_pb.CreateSessionRequest(
      name: name,
      model: model,
      preset: preset,
      org: org,
      repo: repo,
      branch: branch,
    ));
    final s = await agent.getSession(
      agent_pb.GetSessionRequest(id: r.sessionName),
    );
    return s.session;
  }

  /// Delete a session.
  Future<void> deleteSession(String id) async {
    await agent.deleteSession(agent_pb.DeleteSessionRequest(id: id));
  }

  /// List a session's messages.
  Future<List<agent_pb.Message>> messages(String id,
      {String? before, int limit = 30}) async {
    final r = await agent.listMessages(agent_pb.ListMessagesRequest(
        id: id, limit: limit, before: before ?? ''));
    return r.messages;
  }

  /// Enqueue a prompt. Drains the server-stream until the `accepted` event,
  /// then returns the created message id; the turn then runs asynchronously
  /// and is rendered via [watchSession].
  Future<String> prompt(String id, String prompt,
      {List<agent_pb.FileRef> attachments = const []}) async {
    await for (final e in agent.prompt(agent_pb.PromptRequest(
        id: id, prompt: prompt, attachments: attachments))) {
      if (e.event == 'accepted') return e.params['message_id'] ?? '';
    }
    return '';
  }

  /// Live session events (replaces SSE). Yields parsed events.
  Stream<agent_pb.WatchSessionResponse> watchSession(String sessionId,
      {connect.AbortSignal? signal}) {
    return agent.watchSession(agent_pb.WatchSessionRequest(id: sessionId),
        signal: signal);
  }

  /// Switch a session's model.
  Future<String> switchModel(String id, String model) async {
    await agent.setModel(agent_pb.SetModelRequest(id: id, model: model));
    return model;
  }

  /// Update session settings.
  Future<void> updateSettings(String id,
      {String? model,
      String? preset,
      int? maxTurns,
      String? systemPrompt,
      String? locale}) async {
    await agent.updateSettings(agent_pb.UpdateSettingsRequest(
      id: id,
      model: model,
      preset: preset,
      maxTurns: maxTurns,
      systemPrompt: systemPrompt,
      locale: locale,
    ));
  }

  /// Interrupt a running turn.
  Future<bool> interrupt(String id) async {
    final r = await agent.interrupt(agent_pb.InterruptRequest(id: id));
    return r.interrupted;
  }

  /// Compact the conversation history.
  Future<void> compact(String id) async {
    await agent.compact(agent_pb.CompactRequest(id: id));
  }

  /// Fork a session into a new branch/name.
  Future<agent_pb.Session> fork(
      String id, String name, {String? messageId, String? preset}) async {
    final r = await agent.fork(agent_pb.ForkRequest(
        id: id, name: name, messageId: messageId, preset: preset));
    return r.session;
  }

  /// Rename a session.
  Future<agent_pb.Session> rename(String id, String name) async {
    final r = await agent.rename(agent_pb.RenameRequest(id: id, name: name));
    return r.session;
  }

  /// List models.
  Future<List<agent_pb.ModelInfo>> listModels() async {
    final r = await agent.listModels(agent_pb.ListModelsRequest());
    return r.models;
  }

  /// List presets.
  Future<List<agent_pb.Preset>> listPresets() async {
    final r = await agent.listPresets(agent_pb.ListPresetsRequest());
    return r.presets;
  }

  /// Health check.
  Future<agent_pb.HealthResponse> health() async {
    return agent.health(agent_pb.HealthRequest());
  }
}
