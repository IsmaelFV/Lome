/// Excepciones personalizadas para la capa de datos.
///
/// Estas excepciones se lanzan desde DataSources y se capturan
/// en los Repository implementations para convertirlas en [Failure].

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ServerException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthException($code): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Sin conexion a internet'});

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class StorageException implements Exception {
  final String message;

  const StorageException({required this.message});

  @override
  String toString() => 'StorageException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({
    this.message = 'No tienes permisos para esta accion',
  });

  @override
  String toString() => 'PermissionException: $message';
}
