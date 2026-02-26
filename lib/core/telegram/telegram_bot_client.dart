import 'dart:convert';

import 'package:http/http.dart' as http;

/// Telegram Bot API 클라이언트.
///
/// **보안:** 토큰은 서버(Cloud Functions 등) 환경 변수에서만 주입하고,
/// Flutter 앱 바이너리에는 포함하지 마세요.
class TelegramBotClient {
  TelegramBotClient({required String botToken})
      : _baseUrl = 'https://api.telegram.org/bot$botToken';

  final String _baseUrl;

  /// 메시지 전송.
  ///
  /// [chatId]: 개인 채팅 ID 또는 그룹/채널 ID (숫자 또는 @username).
  /// [text]: 전송할 텍스트.
  /// 반환: 성공 시 true, 실패 시 false (응답 본문은 로그 등으로 확인).
  Future<bool> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uri = Uri.parse('$_baseUrl/sendMessage');
    final body = jsonEncode({
      'chat_id': chatId,
      'text': text,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 200;
  }
}
