import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses enveloped auth response', () {
    final result = parseApiMap({
      'data': {
        'user': {'id': '1', 'email': 'a@b.com', 'display_name': 'A', 'role': 'driver'},
        'access_token': 'access',
        'refresh_token': 'refresh',
      },
      'error': null,
    });

    expect(result.isSuccess, isTrue);
    expect(result.data?['access_token'], 'access');
  });

  test('parses flat legacy auth response', () {
    final result = parseApiMap({
      'user': {'id': '1', 'email': 'a@b.com', 'display_name': 'A', 'role': 'driver'},
      'access_token': 'access',
      'refresh_token': 'refresh',
    });

    expect(result.isSuccess, isTrue);
  });

  test('parses api error envelope', () {
    final result = parseApiMap({
      'data': null,
      'error': {'code': 'AUTH_FAILED', 'message': 'Invalid credentials'},
    });

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, 'AUTH_FAILED');
  });
}