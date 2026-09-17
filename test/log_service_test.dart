import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/services/log_service.dart';

void main() {
  test(
    'History sends date and search filters with pagination to the server',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient('http://127.0.0.1:${server.port}', 'test');
      addTearDown(() async {
        await client.dispose();
        await server.close(force: true);
      });
      final captured = server.first.then((request) async {
        final uri = request.uri;
        request.response.headers.contentType = ContentType.json;
        request.response.write('[]');
        await request.response.close();
        return uri;
      });
      await LogService(client: client).getLogs(
        page: 1,
        search: 'Sound, system',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 29),
      );
      final uri = await captured;
      expect(uri.queryParametersAll['created_at'], [
        'gte.${DateTime(2024, 2, 1).toUtc().toIso8601String()}',
        'lt.${DateTime(2024, 3, 1).toUtc().toIso8601String()}',
      ]);
      expect(
        uri.queryParameters['or'],
        contains('item_name.ilike."%Sound, system%"'),
      );
      expect(uri.queryParameters['offset'], '20');
      expect(uri.queryParameters['limit'], '20');
      expect(uri.queryParameters['order'], 'created_at.desc.nullslast,id.desc.nullslast');
    },
  );
}
