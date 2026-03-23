import 'package:cloud_firestore/cloud_firestore.dart';

import 'exceptions.dart';

/// Firebase 예외를 앱 공통 예외로 매핑
AppException mapFirebaseException(Object error, {String? fallbackMessage}) {
  if (error is AppException) {
    return error;
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return PermissionException(
          message: fallbackMessage ?? '권한이 없습니다',
          code: error.code,
          cause: error,
        );
      case 'not-found':
        return NotFoundException(
          message: fallbackMessage ?? '요청한 항목을 찾을 수 없습니다',
          code: error.code,
          cause: error,
        );
      case 'unauthenticated':
        return AuthException(
          message: fallbackMessage ?? '로그인이 필요합니다',
          code: error.code,
          cause: error,
        );
      case 'invalid-argument':
      case 'failed-precondition':
        return ValidationException(
          message: fallbackMessage ?? '입력 내용을 확인해 주세요',
          code: error.code,
          cause: error,
        );
      case 'unavailable':
      case 'deadline-exceeded':
      case 'resource-exhausted':
        return NetworkException(
          message: fallbackMessage ?? '네트워크 연결을 확인해 주세요',
          code: error.code,
          cause: error,
        );
      default:
        return ServerException(
          message: fallbackMessage ?? '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요',
          code: error.code,
          cause: error,
        );
    }
  }

  return ServerException(
    message: fallbackMessage ?? '알 수 없는 오류가 발생했습니다',
    cause: error,
  );
}
