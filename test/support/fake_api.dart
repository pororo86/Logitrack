import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gcmrlogistic/core/auth/app_services.dart';
import 'package:gcmrlogistic/core/storage/token_storage.dart';

class Reply {
  const Reply(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
}

Reply ok(Map<String, dynamic> data) =>
    Reply(200, {'success': true, 'message': 'ok', 'data': data});

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Reply Function(RequestOptions options) handler;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final reply = handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AppServices buildServices(FakeAdapter adapter, {TokenStorage? storage}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://test/api',
      headers: {'Accept': 'application/json'},
    ),
  )..httpClientAdapter = adapter;

  return AppServices.create(storage: storage ?? MemoryTokenStorage(), dio: dio);
}
