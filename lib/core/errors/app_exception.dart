class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Insufficient permissions.']);

  @override
  String toString() => 'UnauthorizedException: $message';
}
