import 'package:flutter/material.dart';

import 'exceptions.dart';

/// 에러를 사용자 친화적 메시지로 변환
class ErrorHandler {
  ErrorHandler._();

  /// 예외를 사용자에게 표시할 메시지로 변환
  static String toUserMessage(Object error, {String? fallback}) {
    if (error is AppException) {
      return error.message ?? _defaultForError(error) ?? fallback ?? '오류가 발생했습니다';
    }
    return _mapCommonErrors(error) ?? fallback ?? '오류가 발생했습니다';
  }

  static String? _defaultForError(AppException e) {
    return switch (e) {
      NetworkException() => '네트워크 연결을 확인해 주세요',
      AuthException() => '로그인이 필요합니다',
      ValidationException() => '입력 내용을 확인해 주세요',
      NotFoundException() => '요청한 항목을 찾을 수 없습니다',
      PermissionException() => '권한이 없습니다',
      ServerException() => '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요',
    };
  }

  static String? _mapCommonErrors(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return '네트워크 연결을 확인해 주세요';
    }
    if (msg.contains('permission') || msg.contains('permission-denied')) {
      return '권한이 없습니다';
    }
    if (msg.contains('not-found') || msg.contains('not found')) {
      return '요청한 항목을 찾을 수 없습니다';
    }
    if (msg.contains('unauthenticated') || msg.contains('auth')) {
      return '로그인이 필요합니다';
    }
    return null;
  }

  /// SnackBar로 에러 표시
  static void showError(BuildContext context, Object error, {String? fallback}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toUserMessage(error, fallback: fallback)),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}
