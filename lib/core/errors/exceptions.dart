class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'An unknown server error occurred.']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'An unknown cache error occurred.']);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'An authentication error occurred.']);

  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'A network error occurred.']);

  @override
  String toString() => 'NetworkException: $message';
}
