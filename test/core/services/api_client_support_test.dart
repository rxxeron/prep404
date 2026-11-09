import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prep404/core/services/api_client.dart';

void main() {
  test('support request sends the caller-stable idempotency key', () async {
    final bodies = <Map<String, dynamic>>[];
    final client = ApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      httpClient: MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{"ok":true}', 201);
      }),
    );

    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        await client.submitSupportRequest(
          category: 'learning_progress',
          subject: 'Progress did not update',
          message: 'My saved topic progress did not update after practice.',
          idempotencyKey: '40000000-0000-4000-8000-000000000987',
        );
      }
    } finally {
      client.dispose();
    }

    expect(bodies, hasLength(2));
    expect(bodies[0]['idempotencyKey'], '40000000-0000-4000-8000-000000000987');
    expect(bodies[1]['idempotencyKey'], bodies[0]['idempotencyKey']);
  });
}
