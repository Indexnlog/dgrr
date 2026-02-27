import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/match_media_model.dart';
import '../../domain/entities/match_media.dart';
import '../providers/match_media_providers.dart';

/// 경기 영상 섹션 (YouTube 플레이리스트 + 타임스탬프 댓글)
class MatchMediaSection extends ConsumerWidget {
  const MatchMediaSection({
    super.key,
    required this.matchId,
    this.opponentName,
  });

  final String matchId;
  final String? opponentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(matchMediaProvider(matchId));

    return mediaAsync.when(
      data: (media) {
        if (media == null) {
          return _EmptyMediaCard(
            matchId: matchId,
            opponentName: opponentName,
          );
        }
        return _MediaCard(media: media, matchId: matchId);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EmptyMediaCard extends ConsumerWidget {
  const _EmptyMediaCard({
    required this.matchId,
    this.opponentName,
  });

  final String matchId;
  final String? opponentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddMediaSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '경기 영상',
                    style: TextStyle(
                      color: Color(0xFFF0F6FC),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'YouTube 플레이리스트 링크 추가',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.add, color: Color(0xFF8B949E), size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddMediaSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddMediaSheet(
        matchId: matchId,
        opponentName: opponentName,
      ),
    );
  }
}

class _MediaCard extends ConsumerWidget {
  const _MediaCard({required this.media, required this.matchId});

  final dynamic media;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistUrl = media.playlistUrl ?? media.videoUrls?.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_filled, color: Colors.red.shade400, size: 24),
              const SizedBox(width: 8),
              const Text(
                '경기 영상',
                style: TextStyle(
                  color: Color(0xFFF0F6FC),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (playlistUrl != null && playlistUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(_ensureHttps(playlistUrl))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'YouTube에서 재생',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, color: Colors.red.shade400, size: 16),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '타임스탬프 댓글',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddCommentSheet(context, ref),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF58A6FF)),
                label: const Text('추가', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 12)),
              ),
            ],
          ),
          if (media.timestampComments != null && media.timestampComments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...media.timestampComments!.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final url = _addTimestampToUrl(playlistUrl ?? '', c.seconds);
                          if (url.isNotEmpty) launchUrl(Uri.parse(url));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.timestamp,
                            style: const TextStyle(
                              color: Color(0xFF58A6FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.text,
                          style: const TextStyle(
                            color: Color(0xFFF0F6FC),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _ensureHttps(String url) {
    if (url.startsWith('http')) return url;
    return 'https://$url';
  }

  String _addTimestampToUrl(String url, int seconds) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(_ensureHttps(url));
    if (uri == null) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, 't': '$seconds'}).toString();
  }

  void _showAddCommentSheet(BuildContext context, WidgetRef ref) {
    final playlistUrl = media.playlistUrl ?? media.videoUrls?.firstOrNull ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddTimestampCommentSheet(
        matchId: matchId,
        mediaId: media.mediaId,
        playlistUrl: playlistUrl,
      ),
    );
  }
}

class _AddMediaSheet extends ConsumerStatefulWidget {
  const _AddMediaSheet({
    required this.matchId,
    this.opponentName,
  });

  final String matchId;
  final String? opponentName;

  @override
  ConsumerState<_AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends ConsumerState<_AddMediaSheet> {
  final _urlController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '경기 영상 링크 추가',
            style: TextStyle(
              color: Color(0xFFF0F6FC),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'YouTube 플레이리스트 또는 영상 URL을 입력하세요. 링크 탭 시 바로 재생됩니다.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://youtube.com/playlist?list=...',
              hintStyle: TextStyle(color: Color(0xFF484F58)),
              filled: true,
              fillColor: const Color(0xFF21262D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: const TextStyle(color: Color(0xFFF0F6FC)),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 입력해 주세요')),
      );
      return;
    }

    final teamId = ref.read(currentTeamIdProvider);
    final uid = ref.read(currentUserProvider)?.uid;
    if (teamId == null || uid == null) return;

    setState(() => _saving = true);
    try {
      final ds = ref.read(matchMediaDataSourceProvider);
      final media = MatchMediaModel(
        mediaId: widget.matchId,
        matchId: widget.matchId,
        opponentTeamName: widget.opponentName,
        playlistUrl: url,
        uploadedBy: uid,
        createdAt: DateTime.now(),
      );
      await ds.upsert(teamId, media);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영상 링크가 저장되었습니다'), backgroundColor: Color(0xFF2EA043)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// 타임스탬프 댓글 추가 시트 (좌표 + 댓글)
class _AddTimestampCommentSheet extends ConsumerStatefulWidget {
  const _AddTimestampCommentSheet({
    required this.matchId,
    required this.mediaId,
    this.playlistUrl,
  });

  final String matchId;
  final String mediaId;
  final String? playlistUrl;

  @override
  ConsumerState<_AddTimestampCommentSheet> createState() =>
      _AddTimestampCommentSheetState();
}

class _AddTimestampCommentSheetState
    extends ConsumerState<_AddTimestampCommentSheet> {
  final _timestampController = TextEditingController();
  final _textController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _timestampController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '타임스탬프 댓글 추가',
            style: TextStyle(
              color: Color(0xFFF0F6FC),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '영상 특정 시점(분:초)과 코멘트를 입력하세요. 탭 시 해당 시점부터 재생됩니다.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timestampController,
            decoration: InputDecoration(
              hintText: '12:34 (분:초)',
              hintStyle: TextStyle(color: Color(0xFF484F58)),
              filled: true,
              fillColor: const Color(0xFF21262D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: const TextStyle(color: Color(0xFFF0F6FC), fontFamily: 'monospace'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: '댓글 내용',
              hintStyle: TextStyle(color: Color(0xFF484F58)),
              filled: true,
              fillColor: const Color(0xFF21262D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: const TextStyle(color: Color(0xFFF0F6FC)),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final timestamp = _timestampController.text.trim();
    final text = _textController.text.trim();
    if (timestamp.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시점과 댓글을 모두 입력해 주세요')),
      );
      return;
    }

    // "12:34" 형식 검증 (분:초)
    final parts = timestamp.split(':');
    if (parts.length < 2 ||
        int.tryParse(parts[0]) == null ||
        int.tryParse(parts[1]) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시점은 "분:초" 형식으로 입력해 주세요 (예: 12:34)')),
      );
      return;
    }

    final teamId = ref.read(currentTeamIdProvider);
    final user = ref.read(currentUserProvider);
    final uid = user?.uid;
    if (teamId == null || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ds = ref.read(matchMediaDataSourceProvider);
      final comment = TimestampComment(
        timestamp: timestamp,
        userId: uid,
        userName: user?.displayName,
        text: text,
        createdAt: DateTime.now(),
      );
      await ds.addTimestampComment(teamId, widget.mediaId, comment);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 저장되었습니다'),
            backgroundColor: Color(0xFF2EA043),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
