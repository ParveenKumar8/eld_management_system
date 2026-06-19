/// Standard API envelope from the NestJS backend.
class ApiResponse<T> {
  const ApiResponse({this.data, this.error});

  final T? data;
  final ApiErrorBody? error;

  bool get isSuccess => error == null && data != null;
}

class ApiErrorBody {
  const ApiErrorBody({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) => ApiErrorBody(
        code: json['code'] as String? ?? 'UNKNOWN',
        message: json['message'] as String? ?? 'Request failed',
      );
}

/// Parses `{ data, error }` responses from the fleet API.
ApiResponse<Map<String, dynamic>> parseApiMap(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    return const ApiResponse(error: ApiErrorBody(code: 'PARSE_ERROR', message: 'Invalid response'));
  }

  final errorJson = raw['error'];
  if (errorJson is Map<String, dynamic>) {
    return ApiResponse(error: ApiErrorBody.fromJson(errorJson));
  }

  final data = raw['data'];
  if (data is Map<String, dynamic>) {
    return ApiResponse(data: data);
  }

  // Backward-compatible flat auth payloads during migration.
  if (raw.containsKey('access_token') && raw.containsKey('user')) {
    return ApiResponse(data: raw);
  }

  return const ApiResponse(error: ApiErrorBody(code: 'EMPTY_RESPONSE', message: 'No data in response'));
}