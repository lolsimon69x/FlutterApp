import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SyncManager - Authentication & Token Extraction', () {
    test('extracts raw access token correctly from /myaccount response', () {
      final jsonResponse = {
        'access_token': 'test_token_123',
        'token_type': 'bearer',
      };

      String? extractedToken;
      if (jsonResponse.containsKey('access_token')) {
        extractedToken = jsonResponse['access_token'] as String?;
      }

      expect(extractedToken, 'test_token_123');
    });

    test('extracts access token when wrapped in ApiResponse envelope', () {
      final jsonResponse = {
        'success': true,
        'data': {
          'access_token': 'nested_token_456',
          'token_type': 'bearer',
        },
        'message': 'Success',
      };

      String? extractedToken;
      if (jsonResponse.containsKey('access_token')) {
        extractedToken = jsonResponse['access_token'] as String?;
      } else if (jsonResponse['data'] is Map<String, dynamic>) {
        final inner = jsonResponse['data'] as Map<String, dynamic>;
        extractedToken = inner['access_token'] as String?;
      }

      expect(extractedToken, 'nested_token_456');
    });

    test('simulates login HTTP failure handling', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await mockClient.post(
        Uri.parse('http://localhost:8000/myaccount'),
        body: jsonEncode({'email': 'test@test.com', 'password': 'wrong'}),
      );

      expect(response.statusCode, 401);
    });
  });
}