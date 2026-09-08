// Web transport: fetch-based (`package:connectrpc/web.dart`) — browser/SPA.
// `caPem` is ignored; browsers use the platform trust store.
import 'package:connectrpc/connect.dart' show HttpClient;
import 'package:connectrpc/web.dart';

HttpClient buildHttpClient({String? caPem}) => createHttpClient();
