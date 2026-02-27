/// 앱 공통 예외 베이스 클래스
sealed class AppException implements Exception {
  const AppException({
    this.message,
    this.code,
    this.cause,
  });

  final String? message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message ?? runtimeType.toString();
}

/// 네트워크 오류 (연결 실패, 타임아웃 등)
class NetworkException extends AppException {
  const NetworkException({
    super.message,
    super.code,
    super.cause,
  });
}

/// 인증 오류 (로그인 실패, 토큰 만료 등)
class AuthException extends AppException {
  const AuthException({
    super.message,
    super.code,
    super.cause,
  });
}

/// 유효성 검사 실패 (잘못된 입력 등)
class ValidationException extends AppException {
  const ValidationException({
    super.message,
    super.code,
    super.cause,
  });
}

/// 리소스 없음 (404)
class NotFoundException extends AppException {
  const NotFoundException({
    super.message,
    super.code,
    super.cause,
  });
}

/// 권한 없음 (403)
class PermissionException extends AppException {
  const PermissionException({
    super.message,
    super.code,
    super.cause,
  });
}

/// Firestore/서버 오류
class ServerException extends AppException {
  const ServerException({
    super.message,
    super.code,
    super.cause,
  });
}
