// Fallback transport (non-web): identical to the io implementation. The
// conditional-import default branch is the "not web" case; it aliases the
// native HTTP/2-over-TLS client so out-of-the-box behavior is consistent.
export 'transport_io.dart' show buildHttpClient;
