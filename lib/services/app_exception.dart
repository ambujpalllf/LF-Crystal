// class AppException implements Exception {
//   final String message;
//   AppException(this.message);
// }

// class BadRequestException extends AppException {
//   BadRequestException(super.message);
// }

// class UnauthorisedException extends AppException {
//   UnauthorisedException(super.message);
// }

// class NotFoundException extends AppException {
//   NotFoundException(super.message);
// }

// class ServerException extends AppException {
//   ServerException(super.message);
// }

// class FetchDataException extends AppException {
//   FetchDataException(super.message);
// }

class FetchDataException implements Exception {
  final String message;
  FetchDataException(this.message);

  @override
  String toString() => "FetchDataException: $message";
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);

  @override
  String toString() => "BadRequestException: $message";
}

class UnauthorisedException implements Exception {
  final String message;
  UnauthorisedException(this.message);

  @override
  String toString() => "UnauthorisedException: $message";
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => "NotFoundException: $message";
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => "ServerException: $message";
}
