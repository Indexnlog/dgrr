import 'package:flutter/foundation.dart';

import 'telegram_bot_client.dart';

/// 경기 상태 변경 시 Telegram Signal Vault 봇으로 알림을 보내는 서비스.
///
/// 보안 참고: 현재 MVP 단계에서는 클라이언트에서 직접 호출하지만,
/// 프로덕션에서는 Cloud Functions로 이전해야 합니다.
class MatchNotificationService {
  MatchNotificationService({
    String? botToken,
    String? chatId,
  })  : _client = TelegramBotClient(
          botToken: botToken ?? _defaultToken,
        ),
        _chatId = chatId ?? _defaultChatId;

  static const _defaultToken =
      '8616695654:AAFWnuieanvWX-Ug_hBxI-Q3jzOLOxfivC8';
  static const _defaultChatId = '6475054244';

  final TelegramBotClient _client;
  final String _chatId;

  /// 경기 성사 알림 (pending -> fixed)
  Future<void> notifyMatchFixed({
    required DateTime matchDate,
    required int currentCount,
    required int minPlayers,
    String? opponentName,
    String? location,
  }) async {
    final dateStr =
        '${matchDate.month}/${matchDate.day}(${_weekday(matchDate.weekday)})';
    final opponent = opponentName ?? '상대 미정';

    final message = StringBuffer()
      ..writeln('[영원FC] 경기 성사!')
      ..writeln()
      ..writeln('$dateStr vs $opponent')
      ..writeln('현재 $currentCount명 참석 확정 (최소 $minPlayers명)')
      ..writeln()
      ..write('장소: ${location ?? "미정"}');

    await _send(message.toString());
  }

  /// 취소 위기 알림 (fixed -> pending 롤백)
  Future<void> notifyMatchAtRisk({
    required DateTime matchDate,
    required int currentCount,
    required int minPlayers,
    String? opponentName,
  }) async {
    final dateStr =
        '${matchDate.month}/${matchDate.day}(${_weekday(matchDate.weekday)})';
    final opponent = opponentName ?? '상대 미정';
    final needed = minPlayers - currentCount;

    final message = StringBuffer()
      ..writeln('[영원FC] 경기 취소 위기!')
      ..writeln()
      ..writeln('$dateStr vs $opponent')
      ..writeln('현재 $currentCount/$minPlayers명 — $needed명 더 필요')
      ..writeln()
      ..write('팀원들에게 참석 독려 부탁드립니다.');

    await _send(message.toString());
  }

  /// D-2 인원 미달 경고
  Future<void> notifyD2Warning({
    required DateTime matchDate,
    required int currentCount,
    required int minPlayers,
    String? opponentName,
  }) async {
    final dateStr =
        '${matchDate.month}/${matchDate.day}(${_weekday(matchDate.weekday)})';
    final needed = minPlayers - currentCount;

    final message = StringBuffer()
      ..writeln('[영원FC] D-2 인원 미달 경고')
      ..writeln()
      ..writeln('$dateStr 경기까지 이틀 남았습니다.')
      ..writeln('현재 $currentCount/$minPlayers명 — $needed명 부족')
      ..writeln()
      ..write('참석 독려가 필요합니다.');

    await _send(message.toString());
  }

  Future<void> _send(String text) async {
    try {
      await _client.sendMessage(chatId: _chatId, text: text);
    } catch (e) {
      debugPrint('[MatchNotificationService] 전송 실패: $e');
    }
  }

  String _weekday(int wd) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[wd - 1];
  }
}
