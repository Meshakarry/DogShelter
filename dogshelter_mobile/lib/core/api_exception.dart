class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.errors});

  final int statusCode;
  final String message;
  final Map<String, List<String>>? errors;

  factory ApiException.fromResponseBody(int statusCode, Object? decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      final rawErrors = decodedBody['errors'];
      return ApiException(
        statusCode: statusCode,
        message: decodedBody['message']?.toString() ?? 'Došlo je do greške.',
        errors: rawErrors is Map<String, dynamic>
            ? rawErrors.map(
                (key, value) => MapEntry(key, (value as List).map((e) => e.toString()).toList()),
              )
            : null,
      );
    }
    return ApiException(statusCode: statusCode, message: 'Došlo je do greške.');
  }

  /// All field errors flattened, in order, for display in a single error banner.
  List<String> get allMessages => errors == null ? [message] : errors!.values.expand((v) => v).toList();

  @override
  String toString() => message;
}
